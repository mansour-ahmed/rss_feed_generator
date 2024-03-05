defmodule RssAutoGenerator.Utils.Url do
  # Regex to validate URLs.
  # Adapted from https://gist.github.com/dperini/729294.
  @link_regex Regex.compile!(
                # protocol identifier
                # user:pass authentication
                # IP address exclusion
                # private & local networks
                # IP address dotted notation octets
                # excludes loopback network 0.0.0.0
                # excludes reserved space >= 224.0.0.0
                # excludes network & broacast addresses
                # (first & last IP address of each class)
                # host name
                # domain name
                # TLD identifier
                # TLD may end with dot
                # port number
                # resource path
                "^" <>
                  "(?:(?:https?|ftp)://)" <>
                  "(?:\\S+(?::\\S*)?@)?" <>
                  "(?:" <>
                  "(?!(?:10|127)(?:\\.\\d{1,3}){3})" <>
                  "(?!(?:169\\.254|192\\.168)(?:\\.\\d{1,3}){2})" <>
                  "(?!172\\.(?:1[6-9]|2\\d|3[0-1])(?:\\.\\d{1,3}){2})" <>
                  "(?:[1-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])" <>
                  "(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}" <>
                  "(?:\\.(?:[1-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))" <>
                  "|" <>
                  "(?:(?:[a-z\\x{00a1}-\\x{ffff}0-9]-*)*[a-z\\x{00a1}-\\x{ffff}0-9]+)" <>
                  "(?:\\.(?:[a-z\\x{00a1}-\\x{ffff}0-9]-*)*[a-z\\x{00a1}-\\x{ffff}0-9]+)*" <>
                  "(?:\\.(?:[a-z\\x{00a1}-\\x{ffff}]{2,}))" <>
                  "\\.?" <>
                  ")" <>
                  "(?::\\d{2,5})?" <>
                  "(?:[/?#]\\S*)?" <>
                  "$",
                "iu"
              )

  @doc """
  Test whether a string is a valid URL.
  """
  def valid_url?(url) do
    Regex.match?(@link_regex, url)
  end

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
      "#{base_url_scheme}://#{base_url_host}#{relative_path}#{query && "?" <> query}"
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
