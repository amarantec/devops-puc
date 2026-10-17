defmodule Kgkm.ChatsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Kgkm.Chats` context;
  """
  alias Kgkm.Repo
  alias Kgkm.Chats.Chat
  alias Kgkm.Chats.ChatMember
  alias Kgkm.Messages.Message
  import Kgkm.AccountsFixtures

  @doc """
  Generate a Chat item.
  """
  def direct_chat_fixture(user1, user2) do
    {:ok, chat} =
      Repo.transact(fn ->
        with {:ok, chat} <- Repo.insert(%Chat{type: :direct}),
             {:ok, _} <- Repo.insert(%ChatMember{chat_id: chat.id, user_id: user1.id}),
             {:ok, _} <- Repo.insert(%ChatMember{chat_id: chat.id, user_id: user2.id}) do
          {:ok, chat}
        end
      end)

    Repo.preload(chat, chat_members: :user)
  end

  def message_fixture(chat, user, attrs \\ %{}) do
    {:ok, message} =
      %Message{}
      |> Message.changeset(
        Enum.into(attrs, %{
          content: "Mensagem de teste",
          chat_id: chat.id
        }),
        %Kgkm.Accounts.Scope{user: user}
      )
      |> Repo.insert()

    Repo.preload(message, [:user, :chat])
  end
end
