defmodule Kgkm.Chats do
  import Ecto.Query, warn: false
  alias Kgkm.Repo
  alias Kgkm.Chats.{Chat, ChatMember}
  alias Kgkm.Accounts.Scope

  def list_user_chats(%Scope{} = scope) do
    user_id = scope.user.id

    from(c in Chat,
      join: cm in ChatMember,
      on: cm.chat_id == c.id,
      where: cm.user_id == ^user_id,
      order_by: [desc: c.updated_at]
    )
    |> Repo.all()
  end

  def get_chat!(%Scope{} = _scope, id) do
    Repo.get!(Chat, id)
  end

  @doc """
  Cria ou recupera um Chat Direto (DM) entre usuário atual e o destinatário;
  """
  def find_or_create_direct_chat(%Scope{} = scope, target_user_id) do
    current_user_id = scope.user.id

    # Procura se já existe um chat direto entre esses dois usuários
    query =
      from c in Chat,
        join: cm1 in ChatMember,
        on: cm1.chat_id == c.id,
        join: cm2 in ChatMember,
        on: cm2.chat_id == c.id,
        where:
          c.type == :direct and cm1.user_id == ^current_user_id and cm2.user_id == ^target_user_id

    case Repo.one(query) do
      %Chat{} = chat ->
        {:ok, chat}

      nil ->
        # Se não existe, cria o chat e insere os dois como membros em uma transação
        Repo.transact(fn ->
          with {:ok, chat} <- Repo.insert(%Chat{type: :direct, title: nil}),
               {:ok, _} <- Repo.insert(%ChatMember{chat_id: chat.id, user_id: current_user_id}),
               {:ok, _} <- Repo.insert(%ChatMember{chat_id: chat.id, user_id: target_user_id}) do
            {:ok, chat}
          end
        end)
    end
  end

  @doc """
  Cria um grupo com um título e uma lista de membros.
  """
  def create_group_chat(%Scope{} = scope, title, member_ids) do
    creator_id = scope.user.id
    all_member_ids = Enum.uniq([creator_id | member_ids])

    Repo.transact(fn ->
      with {:ok, chat} <- Repo.insert(%Chat{type: :group, title: title}) do
        Enum.each(all_member_ids, fn user_id ->
          Repo.insert!(%ChatMember{chat_id: chat.id, user_id: user_id})
        end)

        {:ok, chat}
      end
    end)
  end

  def change_chat(%Scope{} = scope, %Chat{} = chat, attrs \\ %{}) do
    Chat.changeset(chat, attrs, scope)
  end
end
