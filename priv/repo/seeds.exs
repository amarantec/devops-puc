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

# Usamos o atom :user em vez da string "user"
user =
  Repo.get_by(User, email: "teste@kgkm.com") ||
    Repo.insert!(%User{
      email: "teste@kgkm.com",
      role: :user # <-- AQUI: Atom em vez de "user"
    })

chat =
  Repo.insert!(%Chat{
    title: "Sala Geral Elixir",
    type: :group,
    is_muted?: false
  })

Repo.insert!(%Message{
  content: "Olá! Seja bem-vindo ao chat da comunidade.",
  chat_id: chat.id,
  user_id: user.id
})

Repo.insert!(%Message{
  content: "Testando envio de mensagens no LiveView!",
  chat_id: chat.id,
  user_id: user.id
})

IO.puts("✅ Seeds executados com sucesso! Chat ID: #{chat.id}")
