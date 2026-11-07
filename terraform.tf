terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = "~> 1.2"
}

provider "aws" {
  region = "sa-east-1"
}

# Busca a ultima ami do ubuntu 24.04
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # ID oficial da canonical
}

# recupera o vpc padrão para evitar dependencias manuais da rede
data "aws_vpc" "default" {
  default = true
}

# Security Group, definindo as regras do firewall para o app, db e ssh
resource "aws_security_group" "kgkm_sg" {
  name        = "kgkm-chat-prod-sg"
  description = "permite trafego web, conexoes websocket e ssh para a aplicacao"
  vpc_id =  data.aws_vpc.default.id

  ingress {
    description = "HTTP padrao"
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
    description = "Porta da aplicacao"
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

  egress  {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "KGKM-Chat-SG"
  }
}

# Adiciona a chave publica ssh local para liberar o acesso a instancia ec2
resource "aws_key_pair" "deployer" {
  key_name = "kgkm-deploy-key"
  public_key = file("~/.ssh/kgkm_aws_key.pub")
}

# script de inicializacao automaziado, executa no boot da ec2
locals {
  user_data = <<-EOT
    #!/bin/bash
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>&1) 2>&1
    
    echo "instala o docker"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y docker.io wget gnupg

    # inicia o serivo docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu

    echo "criando arquivo de configuracao .env"
    mkdir -p /home/ubuntu/app
    cat << EOF > /home/ubuntu/app/.env
    DB_PORT=5432
    DB_HOST=postgres
    POSTGRES_USER=amarante
    POSTGRES_PASSWORD=123456
    POSTGRES_DB=kgkm_prod
    DATABASE_URL=ecto://amarante:123456@postgres:5432/kgkm_prod
    SECRET_KEY_BASE=vL42mOJ4IPRNTCCDS4nLXGhFYa3P8LrdOTXmOSiTcpLolSd48Pk7/GMSUwP+CAwf
    PORT=4000
    PHX_SERVER=true
    PHX_HOST=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    VAPID_PUBLIC_KEY="BDiDjrZuXPHF1pJ3oUlhgNyaYPpeUa9qBhNnVDKvOiS8IPDi8zzRAxhf9t6ZA7QfKZoHwjw0KTE1ihGaSXB3ob4"
    VAPID_PRIVATE_KEY="OC-xzY4CkCyGgzcny_ECEs5sB-B-eTarfBBkaT0eoTc"
    VAPID_SUBJECT="mailto:administrator@example.com"
    EOF
    chown -R ubuntu:ubuntu /home/ubuntu/app

   echo "criando um db postgres com o docker"
    docker run -d --name kgkm-db \
      --restart always \
      -p 5432:5432 \
      -e POSTGRES_PASSWORD=123456 \
      -e POSTGRES_USER=amarante \
      -e POSTGRES_DB=kgkm_prod \
      -v kgkm-db-data:/var/lib/postgresql \
      postgres:18

    echo "baixa e executa a imagem do app que foi gerada no CI no github"
    docker pull ghcr.io/amarantec/devops-puc:latest

    docker run -d --name kgkm-app \
      --restart always \
      -p 4000:4000 \
      --link kgkm-db:postgres \
      --env-file /home/ubuntu/app/.env \
      ghcr.io/amarantec/devops-puc:latest

    echo "aguarda 15 segundos ate o banco iniciar e executa as migrations para criar as tabelas"
    sleep 15
    docker exec kgkm-app /app/bin/kgkm eval "Kgkm.Release.migrate"

    echo "deploy concluido com sucesso"
  EOT
}

# instancia EC2 principal
resource "aws_instance" "kgkm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  security_groups             = [aws_security_group.kgkm_sg.name]
  key_name                    = aws_key_pair.deployer.key_name
  user_data                   = local.user_data
  user_data_replace_on_change = true

  tags = {
    Name = "kgkm-app"
  }
}

# exibe o ip publico ao terminar de rodar o apply
output "public_ip" {
  value = aws_instance.kgkm.public_ip
}
