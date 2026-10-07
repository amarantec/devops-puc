defmodule Kgkm.Repo.Migrations.AddIsMutedAndNewIndexToChatMembers do
  use Ecto.Migration

  def change do
    alter table(:chat_members) do
      add :is_muted?, :boolean, default: false, null: false
    end

    create index(:chat_members, [:user_id])
  end
end
