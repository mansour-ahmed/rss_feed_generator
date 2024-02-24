defmodule RssAutoGenerator.Repo.Migrations.CreateEntries do
  use Ecto.Migration

  def change do
    create table(:entries) do
      add :title, :string, null: false
      add :link, :string, null: false
      add :author, :string
      add :content, :string, size: 12_000
      add :published_at, :utc_datetime
      add :feed_id, references(:feeds, on_delete: :delete_all)

      timestamps()
    end

    create index(:entries, [:feed_id])
  end
end
