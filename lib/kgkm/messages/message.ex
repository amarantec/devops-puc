defmodule Kgkm.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :content, :string

    belongs_to :chat, Kgkm.Chats.Chat
    belongs_to :user, Kgkm.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs, scope) do
    message
    |> cast(attrs, [:content, :chat_id])
    |> validate_required([:content, :chat_id])
    |> put_change(:user_id, scope.user.id)
  end
end
