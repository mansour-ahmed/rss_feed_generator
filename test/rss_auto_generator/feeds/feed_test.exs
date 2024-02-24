defmodule RssAutoGenerator.Feeds.FeedTest do
  use RssAutoGenerator.DataCase, async: true
  import RssAutoGenerator.FeedsFixtures
  alias RssAutoGenerator.Feeds.Feed

  describe "changeset/2" do
    test "returns valid changeset" do
      assert %{valid?: true} = Feed.changeset(%Feed{}, feed_attrs_fixture())
    end

    test "validates required fields" do
      assert %{
               entry_link_selector: ["can't be blank"],
               title: ["can't be blank"],
               website_url: ["can't be blank"]
             } === errors_on(Feed.changeset(%Feed{}, %{}))
    end

    test "validates length of string fields" do
      attrs =
        feed_attrs_fixture()
        |> Map.put(:title, String.duplicate("a", 501))
        |> Map.put(:author, String.duplicate("a", 501))
        |> Map.put(:description, String.duplicate("a", 1001))

      changeset = Feed.changeset(%Feed{}, attrs)

      assert %{
               title: ["should be at most 500 character(s)"],
               author: ["should be at most 500 character(s)"],
               description: ["should be at most 1000 character(s)"]
             } ===
               errors_on(changeset)
    end

    test "validates url" do
      attrs =
        feed_attrs_fixture()
        |> Map.put(:website_url, "invalid url")
        |> Map.put(:image_url, "invalid url")

      changeset = Feed.changeset(%Feed{}, attrs)

      assert %{
               website_url: ["must be a valid url"],
               image_url: ["must be a valid url"]
             } ===
               errors_on(changeset)
    end
  end
end
