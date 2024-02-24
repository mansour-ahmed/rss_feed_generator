defmodule RssAutoGeneratorWeb.ProxyHtmlController do
  use RssAutoGeneratorWeb, :controller
  alias RssAutoGenerator.Utils.HttpClient
  alias RssAutoGenerator.Proxies.HtmlProxy

  def proxy_html(conn, %{"url" => url}) do
    case HttpClient.get_req(url) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, proxied_html} = HtmlProxy.get_proxied_html(body, url)

        conn
        |> put_resp_content_type("text/html")
        |> send_resp(200, proxied_html)

      _error ->
        send_resp(conn, 404, "Not found")
    end
  end
end
