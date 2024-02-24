defmodule RssAutoGenerator.FeedAnalyzer.HtmlSelectors do
  use Ecto.Schema
  use Instructor.Validator

  @required_fields ~w(entry_link_selector entry_published_at_selector)a

  @doc """
  Selectors to extract RSS feed item data from HTML content.

  ## Fields:
  - selectors: A list of selectors used to extract RSS feed items from the HTML.
    - entry_link_selector: A unique HTML/CSS selector to extract the link of an RSS feed entry from the HTML. The text content of this link will serve as the title for the RSS feed item.
    - entry_published_at_selector: A unique HTML/CSS selector to extract the publication date of an RSS feed entry from the HTML.
  """
  @primary_key false
  embedded_schema do
    field :entry_link_selector, :string
    field :entry_published_at_selector, :string
  end

  @impl true
  def validate_changeset(changeset) do
    changeset
    |> Ecto.Changeset.validate_required(@required_fields)
  end
end
