defmodule RssAutoGeneratorWeb.RssGeneratorController do
  use RssAutoGeneratorWeb, :controller

  alias RssAutoGenerator.Feeds
  alias RssAutoGenerator.FeedGenerator.Builder

  def show(%{host: host} = conn, %{"id" => id}) do
    try do
      %{
        website_url: website_url,
        title: title,
        description: description,
        entries: entries
      } = Feeds.get_feed!(id)

      feed_xml =
        Builder.build_feed(
          website_url,
          entries,
          title,
          description,
          "https://#{host}/#{id}"
        )

      conn
      |> put_resp_content_type("application/xml")
      |> send_resp(200, feed_xml)
    rescue
      _ ->
        conn
        |> put_resp_content_type("application/xml")
        |> send_resp(404, """
          <?xml version="1.0" encoding="UTF-8"?>
          <response>
            <error>
              <code>404</code>
              <message>Not Found</message>
              <details>The requested feed was not found.</details>
            </error>
          </response>
        """)
    end
  end
end
