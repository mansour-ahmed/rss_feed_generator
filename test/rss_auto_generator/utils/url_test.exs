defmodule RssAutoGenerator.Utils.UrlTest do
  use ExUnit.Case, async: true
  alias RssAutoGenerator.Utils.Url

  describe "get_absolute_url/2" do
    test "returns the absolute URL when the URL is relative" do
      url = "/foo"
      base_url = "http://example.com"

      assert Url.get_absolute_url(url, base_url) == "http://example.com/foo"
    end

    test "returns the URL when the URL is absolute" do
      url = "http://example.com/foo"
      base_url = "http://example.com"

      assert Url.get_absolute_url(url, base_url) == "http://example.com/foo"
    end
  end
end
