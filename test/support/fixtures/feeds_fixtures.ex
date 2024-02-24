defmodule RssAutoGenerator.FeedsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RssAutoGenerator.Feeds` context.
  """

  import RssAutoGenerator.EntriesFixtures

  def feed_attrs_fixture(attrs \\ %{}) do
    Map.merge(
      %{
        description: "some description",
        entry_link_selector: "some entry_link_selector",
        entry_published_at_selector: "some entry_published_at_selector",
        image_url: "https://example.com/img.png",
        author: "some author",
        title: "some title",
        website_url: "https://example.com"
      },
      attrs
    )
  end

  @doc """
  Generate a feed.
  """
  def feed_fixture(attrs \\ %{}) do
    {:ok, feed} =
      attrs
      |> feed_attrs_fixture()
      |> RssAutoGenerator.Feeds.create_feed()

    feed
  end

  def feed_with_entries_fixture(attrs \\ %{}) do
    feed = feed_fixture(attrs)
    entry = entry_fixture(%{feed_id: feed.id})

    {feed, entry}
  end
end
