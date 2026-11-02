terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">~ 1.2"
}

provider "aws" {
  region = "sa-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "learn-terraform"
  }
}

# recupera o vpc padrão para evitar que fique vazio
data "aws_vpc" "default" {
  default = true
}

# security Group para o app + db
resource "aws_security_group" "kgkm_sg" {
  name        = "kgkm-chat-prod-sg"
  description = "permite trafego web, conexoes websocket e ssh para a aplicacao"
  vpc_id =  data.aws_vpc.default.id

  ingress {
    description = "HTTP padrão"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS / websockets seguros"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Porta da aplicação"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Acesso ssh admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress = {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "KGKM-Chat-SG"
  }
}

# instância ec2
resource "aws_instance" "kgkm" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.kgkm_sg.name]

  tags = {
    Name = "kgkm-app"
  }
}

output "public_ip" {
  value = aws_instance.kgkm.public_ip
}