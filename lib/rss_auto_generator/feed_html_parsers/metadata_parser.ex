defmodule RssAutoGenerator.FeedHtmlParsers.MetadataParser do
  @doc """
  Parses the HTML content of a page and extracts the summary of the feed entry.
  """
  def parse_feed_entry_content_summary(html) do
    case Floki.parse_document(html) do
      {:ok, document} ->
        summary =
          find_meta(document, :description) ||
            get_feed_content_summary_from_body(document)

        if summary, do: truncate_words(summary), else: nil

      _ ->
        nil
    end
  end

  @doc """
  Parses the HTML content of a page and extracts possible feed metadata from it.
  Supported metadata types: title, description, and author.
  """
  def parse_feed_metadata(html_content) do
    case Floki.parse_document(html_content) do
      {:ok, document} ->
        %{
          title: find_meta(document, :title),
          description: find_meta(document, :description),
          author: find_meta(document, :author)
        }

      _error ->
        nil
    end
  end

  defp truncate_words(text, words_limit \\ 100) do
    words =
      text
      |> String.split()

    if Enum.count(words) <= words_limit do
      Enum.join(words, " ")
    else
      words
      |> Enum.take(words_limit)
      |> Enum.join(" ")
      |> Kernel.<>("...")
    end
  end

  defp get_feed_content_summary_from_body(document) do
    articles_in_document = Floki.find(document, "article")

    if articles_in_document |> Enum.count() > 0 do
      articles_in_document
      |> Enum.at(0)
      |> Floki.text(sep: "\n")
    else
      Floki.text(document, sep: "\n")
    end
  end

  defp find_meta(document, type) when type in [:description, :author, :title] do
    selectors =
      %{
        description: [
          {"meta[name=\"description\"]", "content"},
          {"meta[property=\"og:description\"]", "content"},
          {"meta[name=\"twitter:description\"]", "content"}
        ],
        author: [
          {"meta[name=\"author\"]", "content"},
          {"meta[name=\"twitter:creator\"]", "content"},
          {"meta[property=\"book:author\"]", "content"}
        ],
        title: [
          {"meta[property=\"og:title\"]", "content"},
          {"meta[name=\"twitter:title\"]", "content"},
          {"title", "inner_text"}
        ]
      }

    Enum.reduce_while(selectors[type], nil, fn {selector, attr}, acc ->
      case document
           |> Floki.find(selector)
           |> get_content(attr) do
        nil -> {:cont, acc}
        content -> {:halt, content}
      end
    end)
  end

  defp get_content([], _attr), do: nil

  defp get_content(elements, "inner_text"),
    do:
      elements
      |> List.first()
      |> Floki.text()

  defp get_content(elements, attr) do
    elements
    |> Enum.map(&Floki.attribute(&1, attr))
    |> List.flatten()
    |> List.first()
  end
end
