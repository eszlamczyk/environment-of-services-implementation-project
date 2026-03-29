defmodule Auth.Repo.Migrations.AddAdminRoleColumn do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :admin, :boolean, default: false, null: false
    end
  end

  def down do
    alter table(:users) do
      remove :admin
    end
  end
end
