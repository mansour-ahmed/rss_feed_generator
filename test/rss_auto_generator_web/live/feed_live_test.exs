defmodule RssAutoGeneratorWeb.FeedLiveTest do
  use RssAutoGeneratorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import RssAutoGenerator.FeedsFixtures
  import RssAutoGenerator.EntriesFixtures
  import RssAutoGenerator.Utils.Date, only: [format_date: 1]

  @update_attrs %{
    description: "some updated description",
    title: "some updated title",
    author: "some updated author"
  }
  @invalid_attrs %{
    description: nil,
    title: nil,
    author: nil
  }

  defp create_feed(_) do
    feed = feed_fixture()
    entry = entry_fixture(%{feed_id: feed.id})
    %{feed: feed, entry: entry}
  end

  describe "Index" do
    setup [:create_feed]

    test "lists all feeds", %{conn: conn, feed: feed} do
      {:ok, index_live, html} = live(conn, ~p"/feeds")

      assert html =~ "Feeds"
      assert html =~ feed.description
      assert html =~ feed.title
      assert html =~ format_date(feed.updated_at)

      assert index_live
             |> element("a", "RSS feed link")

      assert index_live
             |> element("a", "feed source link")
    end

    test "navigates to new feed page", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/feeds")

      assert index_live
             |> element("a", "New Feed")
             |> render_click() =~
               "New Feed"

      assert_patch(index_live, ~p"/feeds/new")
    end

    test "deletes feed in listing", %{conn: conn, feed: feed} do
      {:ok, index_live, _html} = live(conn, ~p"/feeds")

      assert index_live
             |> element("#feeds-#{feed.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#feeds-#{feed.id}")
    end
  end

  describe "Show" do
    setup [:create_feed]

    test "displays feed", %{conn: conn, feed: feed, entry: entry} do
      {:ok, show_live, html} = live(conn, ~p"/feeds/#{feed}")

      assert html =~ "Feed: #{feed.title}"

      assert show_live
             |> element("a", "RSS feed link")

      assert show_live
             |> element("a", "feed source link")

      assert html =~ feed.description
      assert html =~ feed.title
      assert html =~ feed.author
      assert html =~ "Entries (1)"
      assert html =~ entry.title
      assert html =~ entry.content
      assert html =~ "Written By: #{entry.author}"
      assert html =~ format_date(entry.published_at)

      assert show_live
             |> element("a", entry.title)

      assert html =~ format_date(feed.updated_at)

      assert show_live
             |> element("a", "Back to feeds")
    end

    test "updates feed within modal", %{conn: conn, feed: feed} do
      {:ok, show_live, _html} = live(conn, ~p"/feeds/#{feed}")

      assert show_live
             |> element("a", "Edit feed's metadata")
             |> render_click() =~
               "Edit feed&#39;s metadata"

      assert_patch(show_live, ~p"/feeds/#{feed}/edit")

      assert show_live
             |> form("#feed-form", feed: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#feed-form", feed: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/feeds/#{feed}")

      html = render(show_live)
      assert html =~ "Feed updated successfully"
      assert html =~ "some updated description"
    end
  end
end
