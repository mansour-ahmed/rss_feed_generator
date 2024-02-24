defmodule RssAutoGenerator.Feeds.Feed do
  use Ecto.Schema
  import Ecto.Changeset
  alias RssAutoGenerator.Utils.Url

  @required_fields ~w(title website_url entry_link_selector)a
  @optional_fields ~w(image_url description author entry_published_at_selector)a

  schema "feeds" do
    field :description, :string
    field :title, :string
    field :website_url, :string
    field :author, :string
    field :image_url, :string
    field :entry_link_selector, :string
    field :entry_published_at_selector, :string
    has_many :entries, RssAutoGenerator.Entries.Entry

    timestamps()
  end

  @doc false
  def changeset(feed, attrs) do
    feed
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:title, min: 1, max: 500)
    |> validate_length(:author, min: 1, max: 500)
    |> validate_length(:description, max: 1000)
    |> validate_url(:website_url)
    |> validate_url(:image_url)
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
