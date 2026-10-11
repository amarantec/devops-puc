defmodule Kgkm.Repo.Migrations.AllowNullContentInMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      modify :content, :text, null: true, from: {:text, false}
    end
  end
end
