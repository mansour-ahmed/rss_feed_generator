defmodule RssAutoGenerator.FeedGenerator.Builder do
  alias Atomex.{Feed, Entry}

  alias RssAutoGenerator.Entries.Entry, as: RssFeedItem

  def build_feed(feed_source_url, entries, feed_title, description, feed_endpoint) do
    feed_source_url
    |> get_canonical_url()
    |> Feed.new(DateTime.utc_now(), feed_title)
    |> Feed.subtitle(description)
    |> Feed.link(feed_source_url, rel: "alternate", type: "text/html")
    |> Feed.link("#{feed_endpoint}/feed.atom",
      rel: "self",
      type: "application/atom+xml"
    )
    |> Feed.entries(Enum.map(entries, &get_entry/1))
    |> Feed.build()
    |> Atomex.generate_document()
  end

  defp get_canonical_url(url) do
    (String.ends_with?(url, "/") && url) || "#{url}/"
  end

  defp get_entry(
         %RssFeedItem{
           title: title,
           link: link,
           published_at: published_at
         } = params
       ) do
    date = published_at || DateTime.utc_now()

    link
    |> Entry.new(date, title)
    |> Entry.link(link, rel: "alternate", type: "text/html")
    |> maybe_add_author(params)
    |> maybe_add_content(params)
    |> Entry.build()
  end

  defp maybe_add_author(entry, %RssFeedItem{author: author} = _)
       when is_binary(author),
       do: entry |> Entry.author(author)

  defp maybe_add_author(entry, _), do: entry

  defp maybe_add_content(entry, %RssFeedItem{content: content} = _)
       when is_binary(content),
       do:
         entry
         |> Entry.summary(content)

  defp maybe_add_content(entry, _), do: entry
end
