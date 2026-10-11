defmodule Kgkm.Repo.Migrations.AddFileUrlToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :file_url, :text
    end
  end
end
