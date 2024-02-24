defmodule RssAutoGenerator.EntriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RssAutoGenerator.Entries` context.
  """

  alias RssAutoGenerator.{Repo, Entries.Entry, FeedsFixtures}

  def entry_attrs_fixture(attrs \\ %{}) do
    Map.merge(
      %{
        author: "some author",
        content: "some content",
        link: "https://example.com",
        published_at: ~U[2024-02-23 15:00:00Z],
        title: "some title"
      },
      attrs
    )
  end

  @doc """
  Generate a entry.
  """
  def entry_fixture(attrs \\ %{}) do
    feed = FeedsFixtures.feed_fixture()

    attrs =
      Map.merge(
        %{
          feed_id: feed.id
        },
        attrs
      )

    attrs =
      attrs
      |> entry_attrs_fixture()

    {:ok, entry} =
      %Entry{}
      |> Entry.changeset(attrs)
      |> Repo.insert()

    entry
  end
end
