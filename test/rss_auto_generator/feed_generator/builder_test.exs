defmodule RssAutoGenerator.FeedGenerator.BuilderTest do
  use ExUnit.Case, async: true

  alias RssAutoGenerator.FeedGenerator.Builder
  alias RssAutoGenerator.Entries.Entry

  describe "build_feed/5" do
    setup do
      feed_source_url = "http://source-example.com"

      entries = [
        %Entry{title: "Title 1", link: "/1", published_at: ~U[2023-07-06 00:00:00Z]},
        %Entry{
          title: "Title 2",
          link: "http://source-example.com/2",
          published_at: ~U[2024-02-16 00:00:00Z]
        }
      ]

      feed_title = "Feed Title"
      description = "Feed Description"
      feed_endpoint = "http://rss-feed-app.com/feeds/foo123"

      %{
        feed_source_url: feed_source_url,
        entries: entries,
        feed_title: feed_title,
        description: description,
        feed_endpoint: feed_endpoint
      }
    end

    test "builds feed with required fields", %{
      feed_source_url: feed_source_url,
      entries: entries,
      feed_title: feed_title,
      description: description,
      feed_endpoint: feed_endpoint
    } do
      expected_link =
        "<link type=\"application/atom+xml\" rel=\"self\" href=\"http://rss-feed-app.com/feeds/foo123/feed.atom\"/>\n"

      expected_alternate_link =
        "<link type=\"text/html\" rel=\"alternate\" href=\"http://source-example.com\"/>\n"

      expected_subtitle = "<subtitle>Feed Description</subtitle>\n"
      expected_id = "<id>http://source-example.com/</id>\n"
      expected_title = "<title>Feed Title</title>\n"

      expected_item =
        "    <link type=\"text/html\" rel=\"alternate\" href=\"/1\"/>\n    <id>/1</id>\n    <title>Title 1</title>\n    <updated>2023-07-06T00:00:00Z</updated>\n"

      expected_item2 =
        "    <link type=\"text/html\" rel=\"alternate\" href=\"http://source-example.com/2\"/>\n    <id>http://source-example.com/2</id>\n    <title>Title 2</title>\n    <updated>2024-02-16T00:00:00Z</updated>\n"

      feed =
        Builder.build_feed(
          feed_source_url,
          entries,
          feed_title,
          description,
          feed_endpoint
        )

      assert feed =~ expected_link
      assert feed =~ expected_alternate_link
      assert feed =~ expected_subtitle
      assert feed =~ expected_id
      assert feed =~ expected_title
      assert feed =~ expected_item
      assert feed =~ expected_item2
    end

    test "builds feed with optional author and content fields", %{
      feed_source_url: feed_source_url,
      feed_title: feed_title,
      description: description,
      feed_endpoint: feed_endpoint
    } do
      entries_with_author_and_content = [
        %Entry{
          title: "Title 1",
          link: "/1",
          author: "John Doe",
          content: "content"
        }
      ]

      feed =
        Builder.build_feed(
          feed_source_url,
          entries_with_author_and_content,
          feed_title,
          description,
          feed_endpoint
        )

      assert feed =~ "<author>\n      <name>John Doe</name>\n    </author>\n"
      assert feed =~ "<summary>content</summary>\n"
    end
  end
end
