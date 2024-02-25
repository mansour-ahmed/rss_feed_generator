defmodule RssAutoGeneratorWeb.RssGeneratorControllerTest do
  use RssAutoGeneratorWeb.ConnCase, async: true

  import RssAutoGenerator.FeedsFixtures

  describe "GET /:id/feed.atom" do
    setup %{conn: conn} do
      {feed, _entry} = feed_with_entries_fixture()

      conn = conn |> Map.put(:host, "foo.com")

      {:ok, conn: conn, feed: feed}
    end

    test "GET /:valid_id/feed.atom returns 200 with xml", %{conn: conn, feed: feed} do
      conn = get(conn, "/#{feed.id}/feed.atom")
      assert response(conn, 200) =~ "xml"

      assert response(conn, 200) =~
               "<link type=\"application/atom+xml\" rel=\"self\" href=\"https://foo.com/#{feed.id}/feed.atom\"/>\n"
    end

    test "GET /:invalid_id/feed.atom returns 404", %{conn: conn} do
      conn = get(conn, "/-1/feed.atom")

      assert response(conn, 404) =~ """
               <?xml version="1.0" encoding="UTF-8"?>
               <response>
                 <error>
                   <code>404</code>
                   <message>Not Found</message>
                   <details>The requested feed was not found.</details>
                 </error>
               </response>
             """
    end
  end
end
