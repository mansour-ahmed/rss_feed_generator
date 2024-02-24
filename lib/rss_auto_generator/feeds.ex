defmodule RssAutoGenerator.Feeds do
  @moduledoc """
  The Feeds context.
  """

  import Ecto.Query, warn: false
  alias RssAutoGenerator.{Repo, Feeds.Feed, Entries.Entry}
  alias Ecto.Multi

  def create_feed_with_entries(feed_params, entries) when entries != [] do
    Multi.new()
    |> Multi.insert(:feed, Feed.changeset(%Feed{}, feed_params))
    |> Multi.run(:entries, fn repo, %{feed: feed} ->
      entry_changesets =
        for entry <- entries do
          Entry.changeset(%Entry{feed_id: feed.id}, entry)
        end

      valid_changesets = Enum.filter(entry_changesets, & &1.valid?)

      if Enum.count(valid_changesets) > 0 do
        Enum.each(valid_changesets, &repo.insert/1)
        {:ok, feed}
      else
        {:error, entry_changesets}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{feed: feed}} ->
        {:ok, feed |> Repo.preload(:entries)}

      {:error, :feed, reason, _} ->
        {:error, reason}

      {:error, :entries, reason, _} ->
        {:error, reason}
    end
  end

  @doc """
  Returns the list of feeds.

  ## Examples

      iex> list_feeds()
      [%Feed{}, ...]

  """
  def list_feeds do
    Feed
    |> Repo.all()
    |> Repo.preload(:entries)
  end

  @doc """
  Gets a single feed.

  Raises `Ecto.NoResultsError` if the Feed does not exist.

  ## Examples

      iex> get_feed!(123)
      %Feed{}

      iex> get_feed!(456)
      ** (Ecto.NoResultsError)

  """
  def get_feed!(id),
    do:
      Feed
      |> Repo.get!(id)
      |> Repo.preload(:entries)

  @doc """
  Creates a feed.

  ## Examples

      iex> create_feed(%{field: value})
      {:ok, %Feed{}}

      iex> create_feed(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_feed(attrs \\ %{}) do
    %Feed{}
    |> Feed.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, feed} -> {:ok, feed |> Repo.preload(:entries)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Updates a feed.

  ## Examples

      iex> update_feed(feed, %{field: new_value})
      {:ok, %Feed{}}

      iex> update_feed(feed, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_feed(%Feed{} = feed, attrs) do
    feed
    |> Feed.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, feed} -> {:ok, feed |> Repo.preload(:entries)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Deletes a feed.

  ## Examples

      iex> delete_feed(feed)
      {:ok, %Feed{}}

      iex> delete_feed(feed)
      {:error, %Ecto.Changeset{}}

  """
  def delete_feed(%Feed{} = feed) do
    Repo.delete(feed)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking feed changes.

  ## Examples

      iex> change_feed(feed)
      %Ecto.Changeset{data: %Feed{}}

  """
  def change_feed(%Feed{} = feed, attrs \\ %{}) do
    Feed.changeset(feed, attrs)
  end
end
