defmodule RssAutoGenerator.Utils.UrlTest do
  use ExUnit.Case, async: true
  alias RssAutoGenerator.Utils.Url

  describe "valid_url?/1" do
    test "returns true when the URL is valid" do
      assert Url.valid_url?("http://example.com")
    end

    test "returns false when the URL is invalid" do
      refute Url.valid_url?("example.com")
      refute Url.valid_url?("https://example")
      refute Url.valid_url?("https://example.")
      refute Url.valid_url?("foo")
      refute Url.valid_url?("http:/example.com")
      refute Url.valid_url?("http//example.com")
    end
  end

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
