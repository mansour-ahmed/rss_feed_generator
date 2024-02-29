defmodule RssAutoGeneratorWeb.FeedLive.Show do
  use RssAutoGeneratorWeb, :live_view

  alias RssAutoGenerator.Feeds
  import RssAutoGeneratorWeb.Feed.FeedPreviewComponent, only: [feed_preview_component: 1]
  import RssAutoGenerator.Utils.Date, only: [format_date: 1]

  import RssAutoGeneratorWeb.Feed.FeedSharedComponents,
    only: [rss_feed_link: 1, rss_feed_source_link: 1]

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Feed: <%= @feed.title %>
      <:actions>
        <.link patch={~p"/feeds/#{@feed}/edit"} phx-click={JS.push_focus()}>
          <.button>Edit feed's metadata</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="RSS Feed">
        <.rss_feed_link feed={@feed} />
      </:item>
      <:item title="Source">
        <.rss_feed_source_link rss_feed_url={@feed.website_url} />
      </:item>
      <:item title="Last updated">
        <%= format_date(@feed.updated_at) %>
      </:item>
    </.list>

    <div class="py-10">
      <.feed_preview_component rss_feed_metadata={@feed} rss_feed_entries={@feed.entries} />
    </div>

    <.back navigate={~p"/feeds"}>Back to feeds</.back>

    <.modal :if={@live_action == :edit} id="feed-modal" show on_cancel={JS.patch(~p"/feeds/#{@feed}")}>
      <.live_component
        module={RssAutoGeneratorWeb.FeedLive.FormComponent}
        id={@feed.id}
        title={@page_title}
        action={@live_action}
        feed={@feed}
        patch={~p"/feeds/#{@feed}"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:feed, Feeds.get_feed!(id))}
  end

  defp page_title(:show), do: "Show Feed"
  defp page_title(:edit), do: "Edit Feed"
end
