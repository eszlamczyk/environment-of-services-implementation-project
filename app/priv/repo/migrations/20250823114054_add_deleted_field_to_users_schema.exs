defmodule Auth.Repo.Migrations.AddDeletedFieldToUsersSchema do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :deleted, :boolean, default: false, null: false
    end
  end

  def down do
    alter table(:users) do
      remove :deleted
    end
  end
end
