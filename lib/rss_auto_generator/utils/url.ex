defmodule RssAutoGenerator.Utils.Url do
  @doc """
  Given a url and a base url, returns the absolute url.
  when the url is relative, it is rewritten to be absolute using the base url.
  when the url is already absolute, it is returned as is.
  """

  def get_absolute_url(url, base_url) when is_binary(url) and is_binary(base_url) do
    %{scheme: url_scheme, path: url_path, query: query} = URI.parse(url)
    relative_url? = url_scheme === nil

    if relative_url? do
      relative_path = get_relative_url(url_path)
      %{scheme: base_url_scheme, host: base_url_host} = URI.parse(base_url)
      "#{base_url_scheme}://#{base_url_host}#{relative_path}?#{query}"
    else
      url
    end
  end

  def get_absolute_url(_, _), do: nil

  defp get_relative_url(path) when is_nil(path) or path === "", do: "/"

  defp get_relative_url(path) do
    if String.starts_with?(path, "/") do
      path
    else
      "/#{path}"
    end
  end
end
