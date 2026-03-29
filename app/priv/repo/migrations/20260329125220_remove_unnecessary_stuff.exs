defmodule Auth.Repo.Migrations.RemoveUnnecessaryStuff do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :provider
      remove :uid
    end
  end
end
