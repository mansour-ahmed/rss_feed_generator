defmodule RssAutoGenerator.FeedHtmlParsers.HtmlParser do
  alias RssAutoGenerator.Utils.Url
  alias RssAutoGenerator.Utils.HttpClient

  def get_html_for_feed_parsers(url) when is_binary(url) do
    if Url.valid_url?(url) do
      case HttpClient.get_req(url, [], 60_000) do
        {:ok, %Finch.Response{status: 200, body: body, headers: headers}} ->
          parse_body(body, headers)

        {:error, reason} ->
          {:error, reason}

        _ ->
          {:error, :unknown_error}
      end
    else
      {:error, :invalid_url}
    end
  end

  def get_html_for_feed_parsers(_), do: {:error, :invalid_url}

  defp parse_body(body, headers) do
    if gzipped?(headers) do
      {:error, :gzipped_content_not_supported}
    else
      {:ok, sanitize_html(body)}
    end
  end

  defp sanitize_html(html) do
    {:ok, document} = html |> Floki.parse_document()

    document
    |> Floki.filter_out("comment")
    |> Floki.filter_out("footer")
    |> Floki.filter_out("nav")
    |> Floki.filter_out("script")
    |> Floki.filter_out("style")
    |> Floki.raw_html()
  end

  defp gzipped?(headers) do
    Enum.any?(headers, fn
      {"content-encoding", "gzip"} -> true
      _ -> false
    end)
  end
end
