defmodule Kgkm.Chats.ChatMember do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "chat_members" do
    field :is_muted?, :boolean, default: false

    belongs_to :chat, Kgkm.Chats.Chat
    belongs_to :user, Kgkm.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(chat_member, attrs) do
    chat_member
    |> cast(attrs, [:chat_id, :user_id, :is_muted?])
    |> validate_required([:chat_id, :user_id])
    |> unique_constraint([:chat_id, :user_id])
  end
end
