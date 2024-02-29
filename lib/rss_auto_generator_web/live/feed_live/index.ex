defmodule RssAutoGeneratorWeb.FeedLive.Index do
  use RssAutoGeneratorWeb, :live_view

  import RssAutoGenerator.Utils.Date, only: [format_date: 1]

  import RssAutoGeneratorWeb.Feed.FeedSharedComponents,
    only: [rss_feed_link: 1, rss_feed_source_link: 1]

  alias RssAutoGenerator.Feeds
  alias RssAutoGenerator.Feeds.Feed

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Feeds
      <:actions>
        <.link patch={~p"/feeds/new"}>
          <.button>New Feed</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="feeds"
      rows={@streams.feeds}
      row_click={fn {_id, feed} -> JS.navigate(~p"/feeds/#{feed}") end}
    >
      <:col :let={{_id, feed}} label="Title"><%= feed.title %></:col>
      <:col :let={{_id, feed}} label="Description"><%= feed.description %></:col>
      <:col :let={{_id, feed}} label="Last updated"><%= format_date(feed.updated_at) %></:col>
      <:col :let={{_id, feed}} label="Entries"><%= feed.entries |> Enum.count() %></:col>
      <:col :let={{_id, feed}} label="RSS link" row_click_disabled?={true}>
        <.rss_feed_link feed={feed} />
      </:col>
      <:col :let={{_id, feed}} label="Feed source" row_click_disabled?={true}>
        <.rss_feed_source_link rss_feed_url={feed.website_url} />
        <div class="sr-only">
          <.link navigate={~p"/feeds/#{feed}"}>Show</.link>
        </div>
      </:col>
      <:action :let={{id, feed}}>
        <.link
          phx-click={JS.push("delete", value: %{id: feed.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
          class="text-red-400 hover:text-red-600"
        >
          <div class="sr-only">Delete</div>
          <.icon name="hero-trash" />
        </.link>
      </:action>
    </.table>

    <.modal :if={@live_action in [:new, :edit]} id="feed-modal" show on_cancel={JS.patch(~p"/feeds")}>
      <.live_component
        module={RssAutoGeneratorWeb.FeedLive.FormComponent}
        id={@feed.id || :new}
        title={@page_title}
        action={@live_action}
        feed={@feed}
        patch={~p"/feeds"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :feeds, Feeds.list_feeds())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Feed")
    |> assign(:feed, Feeds.get_feed!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Feed")
    |> assign(:feed, %Feed{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "All Feeds")
    |> assign(:feed, nil)
  end

  @impl true
  def handle_info({RssAutoGeneratorWeb.FeedLive.FormComponent, {:saved, feed}}, socket) do
    {:noreply, stream_insert(socket, :feeds, feed)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    feed = Feeds.get_feed!(id)
    {:ok, _} = Feeds.delete_feed(feed)

    {:noreply, stream_delete(socket, :feeds, feed)}
  end
end
