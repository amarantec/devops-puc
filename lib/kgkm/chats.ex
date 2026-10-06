defmodule Kgkm.Chats do
  import Ecto.Query, warn: false
  alias Kgkm.Repo
  alias Kgkm.Chats.Chat
  alias Kgkm.Accounts.Scope

  def list_chats(%Scope{} = _scope) do
    # Por enquanto lista todos os chats (em breve filtra pelos membros)
    Repo.all(Chat)
  end

  def get_chat!(%Scope{} = _scope, id) do
    Repo.get!(Chat, id)
  end

  def create_chat(%Scope{} = scope, attrs) do
    %Chat{}
    |> Chat.changeset(attrs, scope)
    |> Repo.insert()
  end

  def change_chat(%Scope{} = scope, %Chat{} = chat, attrs \\ %{}) do
    Chat.changeset(chat, attrs, scope)
  end
end
