# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Kgkm.Repo.insert!(%Kgkm.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Kgkm.Repo
alias Kgkm.Accounts.User
alias Kgkm.Chats.Chat
alias Kgkm.Messages.Message

# Limpa o banco para não dar conflito com os dados antigos sem username
Repo.delete_all(Message)
Repo.delete_all(Chat)
Repo.delete_all(User)

# 1. Usuário de teste principal
user1 =
  Repo.insert!(%User{
    email: "teste@kgkm.com",
    username: "dev_master",
    tag: "1001",
    role: :user
  })

# 2. Segundo usuário para testarmos a busca e início de conversa
user2 =
  Repo.insert!(%User{
    email: "alice@kgkm.com",
    username: "alice",
    tag: "2002",
    role: :user
  })

# 3. Cria uma conversa entre eles
chat =
  Repo.insert!(%Chat{
    title: "DM: dev_master e alice",
    type: :direct,
    is_muted?: false
  })

Repo.insert!(%Message{
  content: "Fala Alice! Testando o chat por tag.",
  chat_id: chat.id,
  user_id: user1.id
})

Repo.insert!(%Message{
  content: "Oi! Ficou muito legal o sistema de tag #2002!",
  chat_id: chat.id,
  user_id: user2.id
})

IO.puts("✅ Seeds executados com sucesso!")
IO.puts("User 1: #{user1.username}##{user1.tag}")
IO.puts("User 2: #{user2.username}##{user2.tag}")
