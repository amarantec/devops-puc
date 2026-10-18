defmodule Kgkm.Repo.Migrations.AddStatusToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :status, :string, default: "sent", null: false
    end
  end
end
