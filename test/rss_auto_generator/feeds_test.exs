defmodule RssAutoGenerator.FeedsTest do
  use RssAutoGenerator.DataCase, async: true

  import RssAutoGenerator.FeedsFixtures
  import RssAutoGenerator.EntriesFixtures
  alias RssAutoGenerator.Entries.Entry
  alias RssAutoGenerator.{Feeds, Feeds.Feed}

  describe "create_feed_with_entries/2" do
    setup do
      feed_params = feed_attrs_fixture()
      entry_params = entry_attrs_fixture()

      %{feed_params: feed_params, entry_params: entry_params}
    end

    test "creates a feed with entries", %{
      feed_params: feed_params,
      entry_params: entry_params
    } do
      %{
        description: description,
        title: title,
        website_url: website_url,
        image_url: image_url,
        entry_link_selector: entry_link_selector,
        entry_published_at_selector: entry_published_at_selector
      } = feed_params

      %{
        author: entry_author,
        content: entry_content,
        link: entry_link,
        published_at: entry_published_at,
        title: entry_title
      } = entry_params

      entries = [entry_params]

      assert {:ok, %Feed{} = feed} = Feeds.create_feed_with_entries(feed_params, entries)

      %{id: feed_id} = feed

      assert %{
               description: ^description,
               title: ^title,
               website_url: ^website_url,
               image_url: ^image_url,
               entry_link_selector: ^entry_link_selector,
               entry_published_at_selector: ^entry_published_at_selector
             } = feed

      assert [
               %{
                 author: ^entry_author,
                 content: ^entry_content,
                 link: ^entry_link,
                 published_at: ^entry_published_at,
                 title: ^entry_title,
                 feed_id: ^feed_id
               }
             ] = feed.entries
    end

    test "doesn't create a feed with invalid entry" do
      feed_params = feed_attrs_fixture()
      entries = [%{}]

      assert Repo.all(Feed) == []
      assert Repo.all(Entry) == []
      assert {:error, _} = Feeds.create_feed_with_entries(feed_params, entries)
      assert Repo.all(Entry) == []
      assert Repo.all(Feed) == []
    end

    test "create a feed with at leawst one valid entry", %{
      feed_params: feed_params,
      entry_params: entry_params
    } do
      entries = [entry_params, %{}]

      assert Repo.all(Feed) == []
      assert Repo.all(Entry) == []
      assert {:ok, %Feed{}} = Feeds.create_feed_with_entries(feed_params, entries)

      assert Entry
             |> Repo.all()
             |> Enum.count() == 1

      assert Feed
             |> Repo.all()
             |> Enum.count() == 1
    end
  end

  describe "list_feed/0" do
    test "returns all feeds" do
      feed = feed_fixture()
      assert Feeds.list_feeds() == [feed]
    end
  end

  describe "get_feed!/1" do
    test "returns the feed with given id" do
      feed = feed_fixture()
      assert Feeds.get_feed!(feed.id) == feed
    end
  end

  describe "create_feed/1" do
    test " creates a feed with valid data" do
      %{
        description: description,
        title: title,
        website_url: website_url,
        image_url: image_url,
        entry_link_selector: entry_link_selector,
        entry_published_at_selector: entry_published_at_selector
      } =
        attrs = feed_attrs_fixture()

      assert {:ok,
              %Feed{
                description: ^description,
                title: ^title,
                website_url: ^website_url,
                image_url: ^image_url,
                entry_link_selector: ^entry_link_selector,
                entry_published_at_selector: ^entry_published_at_selector
              } = _} = Feeds.create_feed(attrs)
    end

    test "invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feeds.create_feed(%{})
    end
  end

  describe "update_feed/2" do
    test "updates the feed with valid data" do
      feed = feed_fixture()

      update_attrs = %{
        description: "some updated description",
        title: "some updated title",
        website_url: "https://test.com",
        image_url: "https://test.com/img.png",
        entry_link_selector: "some updated entry_link_selector",
        entry_published_at_selector: "some updated entry_published_at_selector"
      }

      assert {:ok, %Feed{} = feed} = Feeds.update_feed(feed, update_attrs)
      assert feed.description == update_attrs.description
      assert feed.title == update_attrs.title
      assert feed.website_url == update_attrs.website_url
      assert feed.image_url == update_attrs.image_url
      assert feed.entry_link_selector == update_attrs.entry_link_selector
      assert feed.entry_published_at_selector == update_attrs.entry_published_at_selector
    end

    test "returns error changeset with invalid data" do
      feed = feed_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Feeds.update_feed(feed, %{
                 title: nil
               })

      assert feed == Feeds.get_feed!(feed.id)
    end
  end

  describe "delete_feed/1" do
    test "deletes the feed" do
      feed = feed_fixture()
      assert {:ok, %Feed{}} = Feeds.delete_feed(feed)
      assert_raise Ecto.NoResultsError, fn -> Feeds.get_feed!(feed.id) end
    end
  end

  describe "change_feed/1" do
    test "returns a feed changeset" do
      feed = feed_fixture()
      assert %Ecto.Changeset{} = Feeds.change_feed(feed)
    end
  end
end
