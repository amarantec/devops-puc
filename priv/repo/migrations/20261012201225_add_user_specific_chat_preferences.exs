defmodule Kgkm.Repo.Migrations.AddUserSpecificChatPreferences do
  use Ecto.Migration

  def change do
    # Remove o is_muted global da tabela chats
    alter table(:chats) do
      remove :is_muted?
    end

    # Adiciona as preferências individuais na tabela chat_members
    alter table(:chat_members) do
      add :cleared_at, :utc_datetime
      add :hidden_at, :utc_datetime
    end
  end
end
