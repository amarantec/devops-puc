defmodule Kgkm.Messages do
  @moduledoc """
  The Messages context.
  """

  import Ecto.Query, warn: false
  alias Kgkm.Repo

  alias Kgkm.Messages.Message
  alias Kgkm.Accounts.Scope

  # Assina mensagens de um CHAT especifico
  def subscribe_chat_messages(chat_id) do
    Phoenix.PubSub.subscribe(Kgkm.PubSub, "chat:#{chat_id}:messages")
  end

  defp broadcast_chat_message(chat_id, event) do
    Phoenix.PubSub.broadcast(Kgkm.PubSub, "chat:#{chat_id}:messages", event)
  end

  def list_messages(chat_id) do
    Message
    |> where([m], m.chat_id == ^chat_id)
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  def create_message(%Scope{} = scope, attrs) do
    %Message{}
    |> Message.changeset(attrs, scope)
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        message = Repo.preload(message, :user)
        # Notifica apenas quem está escutando este chat
        broadcast_chat_message(message.chat_id, {:created, message})
        {:ok, message}

      error ->
        error
    end
  end

  def change_message(%Scope{} = scope, %Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs, scope)
  end
end
