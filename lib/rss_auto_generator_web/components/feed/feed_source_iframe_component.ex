defmodule RssAutoGeneratorWeb.Feed.FeedSourceIframeComponent do
  use RssAutoGeneratorWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-[700px] relative">
      <iframe
        id={@id}
        phx-hook="feedSourceIframeHook"
        width="100%"
        height="100%"
        class="absolute"
        src={@rss_feed_url && "/proxy?url=#{@rss_feed_url}"}
        sandbox="allow-same-origin"
      />
      <%= if @loading? do %>
        <div class="animate-pulse bg-gray-600 h-full w-full absolute z-10"></div>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(
        %{
          event: :trigger_highlight,
          payload: payload
        },
        socket
      ) do
    {:ok,
     socket
     |> push_event("highlight", %{
       selector: payload.selector,
       category: payload.category,
       background_color: payload.background_color
     })}
  end

  @impl true
  def update(
        %{
          event: :set_select_mode,
          payload: %{
            enabled: enabled
          }
        },
        socket
      ) do
    {:ok,
     socket
     |> push_event((enabled && "enable_select_mode") || "disable_select_mode", %{})}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def handle_event("item_clicked", %{"selector" => selector}, socket) do
    new_selector = if socket.assigns.selector !== selector, do: selector, else: ""
    notify_parent({:item_clicked_selector, new_selector})

    {:noreply, socket}
  end

  @impl true
  def handle_event("iframe_loaded", _, socket) do
    notify_parent({:iframe_loaded})

    {:noreply, socket}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
