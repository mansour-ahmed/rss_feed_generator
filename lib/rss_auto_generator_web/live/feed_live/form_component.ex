defmodule RssAutoGeneratorWeb.FeedLive.FormComponent do
  use RssAutoGeneratorWeb, :live_component

  alias RssAutoGenerator.Feeds

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Edit feed's metadata</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="feed-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:author]} type="text" label="Author" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Feed</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{feed: feed} = assigns, socket) do
    changeset = Feeds.change_feed(feed)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"feed" => feed_params}, socket) do
    changeset =
      socket.assigns.feed
      |> Feeds.change_feed(feed_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"feed" => feed_params}, socket) do
    save_feed(socket, socket.assigns.action, feed_params)
  end

  defp save_feed(socket, :edit, feed_params) do
    case Feeds.update_feed(socket.assigns.feed, feed_params) do
      {:ok, feed} ->
        notify_parent({:saved, feed})

        {:noreply,
         socket
         |> put_flash(:info, "Feed updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_feed(socket, :new, feed_params) do
    case Feeds.create_feed(feed_params) do
      {:ok, feed} ->
        notify_parent({:saved, feed})

        {:noreply,
         socket
         |> put_flash(:info, "Feed created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
