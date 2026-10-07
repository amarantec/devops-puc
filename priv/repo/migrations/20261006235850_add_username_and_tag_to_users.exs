defmodule Kgkm.Repo.Migrations.AddUsernameAndTagToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :citext, null: false
      add :tag, :string, null: false
    end

    # Garante que NUNCA existirao dois usuarios com o mesmo username E a mesma tag
    create unique_index(:users, [:username, :tag])
    # Indice para acelerar a busca por username
    create index(:users, [:username])
  end
end
