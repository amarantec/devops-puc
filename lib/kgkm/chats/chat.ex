defmodule Kgkm.Chats.Chat do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "chats" do
    field :title, :string
    field :type, Ecto.Enum, values: [:direct, :group]

    has_many :messages, Kgkm.Messages.Message
    has_many :chat_members, Kgkm.Chats.ChatMember
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat, attrs, _scope) do
    chat
    |> cast(attrs, [:title, :type])
    |> validate_required([:type])
  end
end
