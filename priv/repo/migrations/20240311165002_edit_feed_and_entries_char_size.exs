defmodule RssAutoGenerator.Repo.Migrations.EditFeedAndEntriesCharSize do
  use Ecto.Migration

  def change do
    alter table(:feeds) do
      modify :title, :string, size: 500
      modify :author, :string, size: 500
      modify :description, :string, size: 1000
    end

    alter table(:entries) do
      modify :title, :string, size: 500
      modify :author, :string, size: 500
    end
  end
end
