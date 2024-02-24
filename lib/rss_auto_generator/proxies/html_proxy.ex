defmodule RssAutoGenerator.Proxies.HtmlProxy do
  alias RssAutoGenerator.Utils.Url

  @doc """
  Given an HTML string and a base URL, returns a proxied HTML string.

  The proxied HTML string is sanitized and all relative URLs are rewritten to be absolute.
  """
  def get_proxied_html(html, base_url) do
    {:ok, document} =
      html
      |> Floki.parse_document()

    proxied_html =
      document
      |> sanitize_document()
      |> rewrite_relative_urls_in_document(base_url)
      |> Floki.raw_html()

    {:ok, proxied_html}
  end

  defp sanitize_document(document), do: Floki.filter_out(document, "script")

  defp rewrite_relative_urls_in_document(document, base_url) do
    document
    |> Floki.find_and_update(
      "[href], [src]",
      fn
        {el, attrs} ->
          {el,
           attrs
           |> Enum.map(fn
             {"href", url} ->
               {"href", Url.get_absolute_url(url, base_url)}

             {"src", url} ->
               {"src", Url.get_absolute_url(url, base_url)}

             other ->
               other
           end)}

        other ->
          other
      end
    )
  end
end
