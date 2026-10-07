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
alias Kgkm.Chats.{Chat, ChatMember}
alias Kgkm.Messages.Message

Repo.delete_all(Message)
Repo.delete_all(ChatMember)
Repo.delete_all(Chat)
Repo.delete_all(User)

# 1. Usuários de teste
user1 =
  Repo.insert!(%User{
    email: "teste@kgkm.com",
    username: "dev_master",
    tag: "1001",
    role: :user
  })

user2 =
  Repo.insert!(%User{
    email: "alice@kgkm.com",
    username: "alice",
    tag: "2002",
    role: :user
  })

# 2. Chat Direto
chat =
  Repo.insert!(%Chat{
    title: nil,
    type: :direct,
    is_muted?: false
  })

# Vincula ambos como membros
Repo.insert!(%ChatMember{chat_id: chat.id, user_id: user1.id})
Repo.insert!(%ChatMember{chat_id: chat.id, user_id: user2.id})

# 3. Mensagens
Repo.insert!(%Message{
  content: "Fala Alice! Testando o chat com busca de usuários.",
  chat_id: chat.id,
  user_id: user1.id
})

Repo.insert!(%Message{
  content: "Oi! Agora posso te achar digitando alice#2002!",
  chat_id: chat.id,
  user_id: user2.id
})

IO.puts("✅ Seeds atualizados com sucesso!")
