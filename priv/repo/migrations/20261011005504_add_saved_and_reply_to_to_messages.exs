defmodule Kgkm.Repo.Migrations.AddSavedAndReplyToToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :is_saved, :boolean, default: false, null: false
      add :reply_to_id, references(:messages, on_delete: :nilify_all, type: :binary_id)
    end

    create index(:messages, [:is_saved])
    create index(:messages, [:reply_to_id])
  end
end
