defmodule Kgkm.Chats do
  import Ecto.Query, warn: false
  alias Kgkm.Repo
  alias Kgkm.Chats.{Chat, ChatMember}
  alias Kgkm.Accounts.Scope

  def list_user_chats(%Scope{} = scope) do
    user_id = scope.user.id

    chats =
      from(c in Chat,
        join: cm in ChatMember,
        on: cm.chat_id == c.id,
        where: cm.user_id == ^user_id and is_nil(cm.hidden_at),
        order_by: [desc: c.updated_at]
      )
      |> Repo.all()
      |> Repo.preload(chat_members: :user)

    # Adiciona o campo unread_count temporariamente para evitar erro na view
    Enum.map(chats, fn chat -> Map.put(chat, :unread_count, 0) end)
  end

  def get_chat!(%Scope{} = _scope, id) do
    Repo.get!(Chat, id)
    |> Repo.preload(chat_members: :user)
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
        # Se o chat já existia mas estava oculto (hiddent_at) para algum dos usuários
        Repo.update_all(
          from(cm in ChatMember,
            where: cm.chat_id == ^chat.id and cm.user_id == ^current_user_id
          ),
          set: [hidden_at: nil]
        )

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
  def create_group_chat(%Scope{} = scope, title, member_ids) when is_list(member_ids) do
    creator_id = scope.user.id
    # Garante que o criador do grupo está incluído e remove duplicatas
    all_member_ids = Enum.uniq([creator_id | member_ids])

    Repo.transact(fn ->
      with {:ok, chat} <- Repo.insert(%Chat{type: :group, title: title}),
           :ok <- insert_members(chat.id, all_member_ids) do
        {:ok, chat}
      end
    end)
  end

  defp insert_members(chat_id, user_ids) do
    Enum.each(user_ids, fn user_id ->
      Repo.insert!(%ChatMember{chat_id: chat_id, user_id: user_id})
    end)
  end

  @doc """
  Alterna o status de mudo de um chat para um usuário específico.
  """
  def toggle_mute_participant(chat_id, user_id) do
    member = Repo.get_by!(ChatMember, chat_id: chat_id, user_id: user_id)
    new_status = !member.is_muted?

    member
    |> ChatMember.changeset(%{is_muted?: new_status})
    |> Repo.update()
  end

  @doc """
  Define um timestamp 'cleared_at' para o usuário, ocultando mensagens anteriores apenas para ele.
  """
  def clear_history_for_user(chat_id, user_id) do
    member = Repo.get_by!(ChatMember, chat_id: chat_id, user_id: user_id)

    member
    |> ChatMember.changeset(%{cleared_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  @doc """
  Oculta o chat da lista pessoal do usuário (Excluir para mim)
  """
  def hide_chat_for_user(chat_id, user_id) do
    member = Repo.get_by!(ChatMember, chat_id: chat_id, user_id: user_id)

    member
    |> ChatMember.changeset(%{hidden_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  def change_chat(%Scope{} = scope, %Chat{} = chat, attrs \\ %{}) do
    Chat.changeset(chat, attrs, scope)
  end
end
