defmodule RssAutoGenerator.Entries.EntryTest do
  use RssAutoGenerator.DataCase, async: true
  import RssAutoGenerator.EntriesFixtures
  import RssAutoGenerator.FeedsFixtures, only: [feed_fixture: 0]
  alias RssAutoGenerator.Entries.Entry

  describe "changeset/2" do
    setup do
      feed = feed_fixture()

      entry_attrs =
        entry_attrs_fixture(%{
          feed_id: feed.id
        })

      %{entry_attrs: entry_attrs}
    end

    test "returns valid changeset", %{entry_attrs: entry_attrs} do
      assert %{valid?: true} = Entry.changeset(%Entry{}, entry_attrs)
    end

    test "validates required fields" do
      assert %{
               feed_id: ["can't be blank"],
               link: ["can't be blank"],
               title: ["can't be blank"]
             } === errors_on(Entry.changeset(%Entry{}, %{}))
    end

    test "validates length of string fields", %{entry_attrs: entry_attrs} do
      attrs =
        entry_attrs
        |> Map.put(:title, String.duplicate("a", 501))
        |> Map.put(:author, String.duplicate("a", 501))
        |> Map.put(:content, String.duplicate("a", 12_001))

      changeset = Entry.changeset(%Entry{}, attrs)

      assert %{
               title: ["should be at most 500 character(s)"],
               author: ["should be at most 500 character(s)"],
               content: ["should be at most 12000 character(s)"]
             } ===
               errors_on(changeset)
    end

    test "validates url", %{entry_attrs: entry_attrs} do
      attrs =
        entry_attrs
        |> Map.put(:link, "invalid url")

      changeset = Entry.changeset(%Entry{}, attrs)

      assert %{link: ["must be a valid url"]} === errors_on(changeset)
    end

    test "validates feed_id" do
      attrs =
        entry_attrs_fixture()
        |> Map.put(:feed_id, -1)

      changeset = Entry.changeset(%Entry{}, attrs)

      assert %{feed_id: ["must be a valid feed id"]} === errors_on(changeset)
    end
  end
end
