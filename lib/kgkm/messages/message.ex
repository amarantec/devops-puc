defmodule Kgkm.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :content, :string
    field :is_saved, :boolean, default: false
    field :file_url, :string

    belongs_to :chat, Kgkm.Chats.Chat
    belongs_to :user, Kgkm.Accounts.User

    # Auto-relacionamento para mensagens respondidas
    belongs_to :reply_to, Kgkm.Messages.Message, foreign_key: :reply_to_id
    has_many :replies, Kgkm.Messages.Message, foreign_key: :reply_to_id
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs, scope) do
    message
    |> cast(attrs, [:content, :chat_id, :is_saved, :reply_to_id, :file_url])
    |> validate_required([:chat_id])
    |> validate_content_or_file()
    |> put_change(:user_id, scope.user.id)
  end

  defp validate_content_or_file(changeset) do
    content = get_field(changeset, :content)
    file_url = get_field(changeset, :file_url)
    content_blank? = is_nil(content) || String.trim(content) == ""
    file_blank? = is_nil(file_url) || String.trim(file_url) == ""

    if content_blank? && file_blank? do
      add_error(changeset, :content, "Escreva uma mensagem ou envie um arquivo")
    else
      changeset
    end
  end
end
