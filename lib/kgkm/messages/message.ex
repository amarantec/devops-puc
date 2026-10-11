defmodule Kgkm.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :content, :string
    field :is_saved, :boolean, default: false

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
    |> cast(attrs, [:content, :chat_id, :is_saved, :reply_to_id])
    |> validate_required([:content, :chat_id])
    |> put_change(:user_id, scope.user.id)
  end
end
