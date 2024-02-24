defmodule RssAutoGenerator.Entries.Entry do
  use Ecto.Schema
  import Ecto.Changeset
  alias RssAutoGenerator.Feeds
  alias RssAutoGenerator.Utils.Url

  @required_fields ~w(title link feed_id)a
  @optional_fields ~w(author content published_at)a

  schema "entries" do
    field :link, :string
    field :title, :string
    field :author, :string
    field :content, :string
    field :published_at, :utc_datetime
    belongs_to :feed, RssAutoGenerator.Feeds.Feed

    timestamps()
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:title, min: 1, max: 500)
    |> validate_length(:author, max: 500)
    |> validate_length(:content, max: 12_000)
    |> validate_url(:link)
    |> validate_feed_id(:feed_id)
  end

  defp validate_feed_id(changeset, field) do
    case get_field(changeset, field) do
      nil ->
        changeset

      feed_id ->
        try do
          Feeds.get_feed!(feed_id)
          changeset
        rescue
          _ ->
            add_error(changeset, field, "must be a valid feed id")
        end
    end
  end

  defp validate_url(changeset, field) do
    case get_field(changeset, field) do
      nil ->
        changeset

      value ->
        if Url.valid_url?(value) do
          changeset
        else
          add_error(changeset, field, "must be a valid url")
        end
    end
  end
end
