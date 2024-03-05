defmodule RssAutoGenerator.FeedAnalyzer.HtmlSelectors do
  use Ecto.Schema
  use Instructor.Validator
  alias RssAutoGenerator.FeedHtmlParsers.EntryParserUtils

  @required_fields ~w(entry_link_selector entry_published_at_selector)a

  @doc """
  Selectors to extract RSS feed item data from HTML content.

  ## Fields:
  - selectors: A list of selectors used to extract RSS feed items from the HTML.
    - entry_link_selector: A HTML/CSS selector to extract the link of an RSS feed entry from the HTML. The text content of this link will serve as the title for the RSS feed item.
    - entry_published_at_selector: A HTML/CSS selector to extract the publication date of an RSS feed entry from the HTML.
  """
  @primary_key false
  embedded_schema do
    field :entry_link_selector, :string
    field :entry_published_at_selector, :string
  end

  @impl true
  def validate_changeset(changeset, %{raw_html: raw_html}) do
    changeset
    |> Ecto.Changeset.validate_required(@required_fields)
    |> validate_selectors(:entry_link_selector, raw_html)
  end

  defp validate_selectors(changeset, field, raw_html) do
    value =
      Ecto.Changeset.get_field(changeset, field)

    if selector_valid?(value, raw_html),
      do: changeset,
      else:
        Ecto.Changeset.add_error(
          changeset,
          field,
          "must be a valid selector that matches at least one element in the HTML content."
        )
  end

  defp selector_valid?(selector, html) do
    case Floki.parse_document(html) do
      {:ok, document} ->
        EntryParserUtils.selector_has_matches?(selector, document)

      _error ->
        false
    end
  end
end
