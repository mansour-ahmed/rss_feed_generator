defmodule RssAutoGeneratorWeb.Feed.FeedUrlFormComponent.Form do
  use Ecto.Schema

  import Ecto.Changeset
  alias RssAutoGenerator.Utils.Url

  @required_fields ~w(url)a

  @primary_key false
  embedded_schema do
    field :url, :string
  end

  def changeset(form, params \\ %{}) do
    form
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_url(:url)
  end

  defp validate_url(changeset, field) do
    case get_field(changeset, field) do
      nil ->
        changeset

      value ->
        parsed_url = parse_url(value)

        if Url.valid_url?(parsed_url) do
          put_change(changeset, field, parsed_url)
        else
          add_error(changeset, field, "must be a valid url")
        end
    end
  end

  defp parse_url(url) do
    url = url |> String.trim()
    %{scheme: url_scheme} = URI.parse(url)

    if url_scheme, do: url, else: "https://#{url}"
  end
end

defmodule RssAutoGeneratorWeb.Feed.FeedUrlFormComponent do
  use RssAutoGeneratorWeb, :live_component

  alias RssAutoGeneratorWeb.Feed.FeedUrlFormComponent.Form

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center flex-col space-y-4">
      <.simple_form
        for={@form}
        id="feed_url_form"
        phx-submit="submit"
        phx-change="validate"
        phx-target={@myself}
      >
        <div class="flex flex-col justify-center items-center space-y-4 text-center">
          <.input
            id="rss_feed_url"
            label="Website URL to analyze"
            phx-debounce={100}
            field={@form[:url]}
            type="text"
          />
          <.button disabled={!@form.source.valid? || @loading?}>
            <span class="flex flex-row justify-center items-center gap-2">
              <.loading_indicator loading?={@loading?} />
              <%= (@loading? && "Generating...") || "Generate" %>
            </span>
          </.button>
        </div>
      </.simple_form>
      <div :if={!@form.source.valid? && !@loading?} class="pt-5 flex flex-row items-center gap-2">
        <h2 class="text-lg font-medium">Try</h2>
        <.auto_fill_button label="plurrrr.com" url="https://plurrrr.com" target={@myself} />
        <.auto_fill_button label="eurekalert.org" url="https://www.eurekalert.org" target={@myself} />
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(
       Form.changeset(%Form{}, %{
         url: assigns.rss_feed_url
       })
     )}
  end

  @impl true
  def handle_event("validate", %{"form" => form_params}, socket) do
    changeset =
      %Form{}
      |> Form.changeset(form_params)

    changeset =
      if form_params["url"] !== "", do: Map.put(changeset, :action, :validate), else: changeset

    {:noreply,
     assign_form(
       socket,
       changeset
     )}
  end

  @impl true
  def handle_event("submit", _, %{assigns: %{form: %{source: %{changes: %{url: url}}}}} = socket) do
    changeset =
      %Form{}
      |> Form.changeset(%{
        url: url
      })

    notify_parent({:feed_url, url})

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("autofill", %{"url" => url}, socket) do
    changeset =
      %Form{}
      |> Form.changeset(%{
        url: url
      })

    notify_parent({:feed_url, url})

    {:noreply, assign_form(socket, changeset)}
  end

  defp loading_indicator(assigns) do
    ~H"""
    <svg
      :if={@loading?}
      class="animate-spin h-5 w-5 text-white"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
    >
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
      </circle>
      <path
        class="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      >
      </path>
    </svg>
    """
  end

  defp auto_fill_button(assigns) do
    ~H"""
    <button
      type="button"
      class="inline-flex items-center rounded-md bg-yellow-50 px-2 py-1 text-xl font-medium text-yellow-800 ring-1 ring-inset ring-yellow-600/20 hover:cursor-pointer"
      phx-click="autofill"
      phx-value-url={@url}
      phx-target={@target}
    >
      <%= @label %>
    </button>
    """
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(form: to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
