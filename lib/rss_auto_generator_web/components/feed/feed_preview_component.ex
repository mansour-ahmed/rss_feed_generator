defmodule RssAutoGeneratorWeb.Feed.FeedPreviewComponent do
  use Phoenix.Component

  import RssAutoGeneratorWeb.CoreComponents, only: [icon: 1]
  import RssAutoGeneratorWeb.Feed.FeedSharedComponents, only: [get_feed_errors: 2]
  alias RssAutoGenerator.Utils.Date

  attr :rss_feed_metadata, :map, default: %{}
  attr :rss_feed_entries, :list, default: []
  attr :selector_colors, :map, default: nil
  attr :loading?, :boolean, default: false
  attr :highlight_headers, :boolean, default: false
  attr :entries_content_loading?, :boolean, default: false

  def feed_preview_component(%{loading?: true} = assigns) do
    ~H"""
    <.preview_container>
      <.gig_list_loading_skeleton />
    </.preview_container>
    """
  end

  def feed_preview_component(assigns) do
    ~H"""
    <.preview_container>
      <%= if @rss_feed_metadata do %>
        <div>
          <.field_header
            field_label="Title"
            field_value={@rss_feed_metadata.title}
            highlight_header={@highlight_headers}
          />
          <h3><%= @rss_feed_metadata.title %></h3>
        </div>
        <div :if={@rss_feed_metadata.description}>
          <.field_header
            field_label="Description"
            field_value={@rss_feed_metadata.description}
            highlight_header={@highlight_headers}
          />
          <p><%= @rss_feed_metadata.description %></p>
        </div>
        <div :if={@rss_feed_metadata.author}>
          <.field_header
            field_label="Author"
            field_value={@rss_feed_metadata.author}
            highlight_header={@highlight_headers}
          />
          <p><%= @rss_feed_metadata.author %></p>
        </div>
      <% end %>
      <%= if get_feed_errors(@rss_feed_metadata, @rss_feed_entries) === [] do %>
        <.field_header
          field_label={"Entries (#{@rss_feed_entries |> Enum.count()})"}
          field_value={@rss_feed_entries !== []}
          highlight_header={@highlight_headers}
        />
        <ul class="space-y-5">
          <%= for entry <- @rss_feed_entries do %>
            <li>
              <.entry
                entry={entry}
                selector_colors={@selector_colors}
                entries_content_loading?={@entries_content_loading?}
              />
            </li>
            <hr class="w-1/2 mx-auto" />
          <% end %>
        </ul>
      <% else %>
        <.field_header
          field_label="Entries"
          field_value={false}
          highlight_header={@highlight_headers}
        />
      <% end %>
    </.preview_container>
    """
  end

  defp entry(assigns) do
    ~H"""
    <article>
      <a class="underline" href={@entry.link} target="_blank">
        <h4 style={
          if @selector_colors,
            do: "background-color: #{@selector_colors.entry_link_selector}"
        }>
          <%= @entry.title %>
        </h4>
      </a>
      <div :if={@entries_content_loading? && !@entry.content} class="animate-pulse">
        <div class="bg-gray-200 h-4 w-1/2 my-4"></div>
        <div class="bg-gray-200 h-4 w-3/4 my-4"></div>
      </div>
      <p :if={@entry.content} class="py-4"><%= @entry.content %></p>
      <p :if={@entry.author}>Written By: <%= @entry.author %></p>
      <time
        :if={@entry.published_at}
        style={
          if @selector_colors,
            do: "background-color: #{@selector_colors.entry_published_at_selector}"
        }
      >
        <%= @entry.published_at |> Date.format_date() %>
      </time>
    </article>
    """
  end

  slot :inner_block, required: true

  defp preview_container(assigns) do
    ~H"""
    <div class="card bg-gray-50 w-full h-[700px] overflow-scroll space-y-6 py-6 px-10">
      <h2 class="font-bold text-lg">Feed Preview</h2>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :highlight_header, :boolean, default: false
  attr :field_label, :string, required: true
  attr :field_value, :any

  defp field_header(%{highlight_header: true} = assigns) do
    ~H"""
    <h2 class="font-bold">
      <span class={[
        (@field_value && "text-green-600") || "text-red-600",
        "flex flex-row items-center"
      ]}>
        <%= @field_label %>
        <.icon name={(@field_value && "hero-check-solid") || "hero-x-mark-solid"} />
      </span>
    </h2>
    """
  end

  defp field_header(assigns) do
    ~H"""
    <h2 class="font-bold">
      <%= @field_label %>
    </h2>
    """
  end

  defp gig_list_loading_skeleton(assigns) do
    ~H"""
    <div class="animate-pulse space-y-11">
      <div>
        <div class="bg-gray-400 h-5 w-1/2 my-5"></div>
        <div class="bg-gray-300 h-5 w-2/3 my-5"></div>
      </div>
      <%= for _ <- 1..6 do %>
        <div>
          <div class="bg-gray-200 h-4 w-1/2 my-4"></div>
          <div class="bg-gray-200 h-4 w-3/4 my-4"></div>
          <hr class="w-1/2 mx-auto" />
        </div>
      <% end %>
    </div>
    """
  end
end
