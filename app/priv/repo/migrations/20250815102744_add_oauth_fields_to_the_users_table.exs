defmodule Auth.Repo.Migrations.AddOauthFieldsToTheUsersTable do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :provider, :string
      add :uid, :string
    end
  end

  def down do
    alter table(:users) do
      remove :provider
      remove :uid
    end
  end
end
