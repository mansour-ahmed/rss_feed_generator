defmodule RssAutoGenerator.Repo.Migrations.CreateFeeds do
  use Ecto.Migration

  def change do
    create table(:feeds) do
      add :title, :string, null: false
      add :website_url, :string, null: false
      add :description, :string
      add :author, :string
      add :image_url, :string
      add :entry_link_selector, :string, null: false
      add :entry_published_at_selector, :string

      timestamps()
    end
  end
end
