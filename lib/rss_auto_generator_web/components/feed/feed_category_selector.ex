defmodule RssAutoGeneratorWeb.Feed.FeedCategorySelector do
  use RssAutoGeneratorWeb, :live_component

  def render(%{loading?: true} = assigns) do
    ~H"""
    <div class="animate-pulse">
      <div class="bg-gray-400 h-5 w-1/2 my-5"></div>
      <div class="bg-gray-300 h-10 w-2/3 my-5"></div>
      <div class="bg-gray-200 h-5 w-2/3 my-5"></div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form>
      <.input
        id="category_select"
        type="select"
        name="category"
        label="Add data to feed"
        phx-target={@myself}
        options={[
          {"None", nil},
          {"Feed item's links", :entry_link_selector},
          {"Feed item's publishing date - Optional", :entry_published_at_selector}
        ]}
        value={@selected_category}
        phx-change="change_category"
      />
      <p class="py-5">
        Select Mode:
        <span class={[(@selected_category && "text-green-600") || "text-red-600", "font-bold"]}>
          <%= (@selected_category && "ON") || "OFF" %>
        </span>
        - <%= (@selected_category &&
                 "Select data by clicking on items inside the feed source below 👇🏽") ||
          "Select an item from above ☝🏽" %>
      </p>
    </form>
    """
  end

  @impl true
  def handle_event(
        "change_category",
        %{"category" => category},
        socket
      ) do
    notify_parent({:category_selected, category})

    {:noreply, socket}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
