defmodule RssAutoGeneratorWeb.Feed.FeedSharedComponents do
  use Phoenix.VerifiedRoutes,
    endpoint: RssAutoGeneratorWeb.Endpoint,
    router: RssAutoGeneratorWeb.Router

  use Phoenix.Component

  import RssAutoGeneratorWeb.CoreComponents, only: [button: 1, icon: 1]

  def rss_feed_link(assigns) do
    ~H"""
    <a href={~p"/#{@feed}/feed.atom"} target="blank" class="text-yellow-500 hover:text-yellow-400">
      <div class="sr-only">RSS feed link</div>
      <.icon name="hero-rss-solid" />
    </a>
    """
  end

  def rss_feed_source_link(assigns) do
    ~H"""
    <a href={@rss_feed_url} target="blank">
      <div class="sr-only">Feed source link</div>
      <.icon name="hero-link" />
    </a>
    """
  end

  def save_feed_button(assigns) do
    ~H"""
    <div class="pt-10 w-1/2 mx-auto flex flex-col items-center justify-center">
      <.button
        phx-click="save"
        disabled={get_feed_errors(@rss_feed_metadata, @rss_feed_entries) !== []}
      >
        Save Feed
      </.button>
      <%= if get_feed_errors(@rss_feed_metadata, @rss_feed_entries) !== [] do %>
        <p role="alert" class="text-red-600 pt-1">
          <%= "Feed's " <>
            Enum.join(get_feed_errors(@rss_feed_metadata, @rss_feed_entries), ", ") <>
            " are missing" %>
        </p>
      <% end %>
    </div>
    """
  end

  def get_feed_errors(metadata, entries) do
    entries_invalid? =
      entries === [] ||
        entries
        |> Enum.at(0)
        |> Map.get(:link) === nil

    entries_errors = (entries_invalid? && ["entry links"]) || []

    title_invalid? =
      metadata &&
        (metadata.title === nil ||
           metadata.title |> String.length() === 0)

    title_errors = (title_invalid? && ["title"]) || []

    entries_errors ++ title_errors
  end
end
