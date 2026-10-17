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

  def list_messages(chat_id, user_id) do
    # Busca o member para checar se há uma data de limpeza de histórico
    case Repo.get_by(Kgkm.Chats.ChatMember, chat_id: chat_id, user_id: user_id) do
      nil ->
        []

      member ->
         cleared_at = member.cleared_at

        query =
          Message
          |> where([m], m.chat_id == ^chat_id)

        query =
          if cleared_at do
            where(query, [m], m.inserted_at > ^cleared_at)
          else
            query
          end

        query
        |> order_by([m], asc: m.inserted_at)
        |> Repo.all()
        |> Repo.preload([:user, reply_to: :user])
    end
  end

  def create_message(%Scope{} = scope, attrs) do
    %Message{}
    |> Message.changeset(attrs, scope)
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        message = Repo.preload(message, [:user, reply_to: :user, chat: [chat_members: :user]])
        # Notifica apenas quem está escutando este chat
        broadcast_chat_message(message.chat_id, {:created, message})
        
        # --- DISPARO DE PUSH PARA OS OUTROS MEMBROS ---
        chat_members = message.chat.chat_members || []
        
        Enum.each(chat_members, fn member ->
        	# Se o membro nao for quem enviou e nao mutou o chat
        	if member.user_id != message.user_id && !member.is_muted? do
        		recipient_scope = %Kgkm.Accounts.Scope{user: member.user}
        		sender_name = (message.user && message.user.username) || "Alguém"
        		
        		Kgkm.Accounts.send_push_notification_to_user(
        			recipient_scope,
        			"Nova mensagem de #{sender_name}",
        			message.content || "Enviou um anexo",
        			"/chats/#{message.chat_id}"
        			)
        		end
        	end)
        	# --------------------
        {:ok, message}

      error ->
        error
    end
  end

  def get_message!(id) do
    Message
    |> Repo.get!(id)
    |> Repo.preload([:user, reply_to: :user])
  end

  def save_message(message_id) do
    message = Repo.get!(Message, message_id)

    message
    |> Ecto.Changeset.change(%{is_saved: true})
    |> Repo.update()
  end

  def list_user_saved_messages(%Scope{} = scope) do
    # Busca as mensagens salvas do chat
    Message
    |> join(:inner, [m], c in assoc(m, :chat))
    |> join(:inner, [m, c], cm in assoc(c, :chat_members))
    |> where([m, c, cm], cm.user_id == ^scope.user.id and m.is_saved == true)
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
    |> Repo.preload([:user, chat: [chat_members: :user]])
  end

  def change_message(%Scope{} = scope, %Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs, scope)
  end
end
