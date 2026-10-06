defmodule Kgkm.Repo.Migrations.CreateChatTable do
  use Ecto.Migration

  def change do
    create table(:chats, primary_key: false) do
      add :id, :binary_id, primary_key: true
      # Ex: "Geral", "Projeto Elixir" ou nil para DMs
      add :title, :string
      # "direct" ou "group"
      add :type, :string, default: "direct"
      add :is_muted?, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create table(:chat_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :chat_id, references(:chats, on_delete: :delete_all, type: :binary_id), null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:chat_members, [:chat_id, :user_id])

    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text, null: false
      add :chat_id, references(:chats, on_delete: :delete_all, type: :binary_id), null: false
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:chat_id])
    create index(:messages, [:user_id])
  end
end
