defmodule RssAutoGenerator.Proxies.HtmlProxyTest do
  use ExUnit.Case, async: true
  alias RssAutoGenerator.Proxies.HtmlProxy

  describe "get_proxied_html/2" do
    test "get_proxied_html/2" do
      html = """
      <html>
        <head>
          <title>Test</title>
        </head>
        <body>
          <a href="/test">Test</a>
          <img src="/test.png" />
          <script src="/test.js"></script>
        </body>
      </html>
      """

      base_url = "http://example.com"

      expected =
        """
        <html><head><title>Test</title></head><body><a href="http://example.com/test">Test</a><img src="http://example.com/test.png"/></body></html>
        """
        |> String.trim()

      assert HtmlProxy.get_proxied_html(html, base_url) == {:ok, expected}
    end
  end
end
