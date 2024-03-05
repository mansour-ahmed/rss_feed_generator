defmodule RssAutoGeneratorWeb.FeedLive.New do
  use RssAutoGeneratorWeb, :live_view

  import RssAutoGeneratorWeb.Feed.FeedPreviewComponent, only: [feed_preview_component: 1]
  import RssAutoGeneratorWeb.Feed.FeedSharedComponents, only: [save_feed_button: 1]
  alias Phoenix.LiveView.AsyncResult
  alias RssAutoGenerator.{Feeds, Entries.Entry}
  alias RssAutoGenerator.FeedAnalyzer.{LlmAnalyzer, HtmlSelectors}
  alias RssAutoGenerator.FeedHtmlParsers.{MetadataParser, EntryParser, HtmlParser}
  alias RssAutoGeneratorWeb.Utils.UserAgent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        id="feed_url_form"
        module={RssAutoGeneratorWeb.Feed.FeedUrlFormComponent}
        loading?={@rss_feed && (@rss_feed.loading || (@rss_feed.ok? && @iframe_loading?))}
        rss_feed_url={@rss_feed && @rss_feed.result && @rss_feed.result.url}
      />

      <%= if @rss_feed do %>
        <p :if={@rss_feed.failed} class="text-red-600 text-center text-lg pt-20" role="alert">
          We're sorry, but there was an error loading the feed. Please try again with a different URL.
        </p>
        <div :if={rss_feed = @rss_feed.ok? && @rss_feed.result}>
          <p :if={@rss_feed.result.selectors_by === :llm} class="text-center text-lg py-10">
            <%= if Enum.count(@rss_feed.result.entries) > 0  do %>
              <span class="text-green-600">
                Our AI has selected elements for you, and your feed preview is now ready!
              </span>
              Found an issue? Please edit the feed details below!
            <% else %>
              <span class="text-red-600">
                We were unable to detect any feed items.
              </span>
              Could you assist us by selecting feed items below?
            <% end %>
          </p>
          <div>
            <div class="w-1/2 pr-10">
              <.live_component
                id="feed_category_selector"
                module={RssAutoGeneratorWeb.Feed.FeedCategorySelector}
                loading?={@iframe_loading?}
                selected_category={@selected_category}
              />
            </div>
            <div class="flex flex-col sm:flex-row space-y-10 sm:space-y-0 sm:space-x-10">
              <.live_component
                id="feed_iframe"
                module={RssAutoGeneratorWeb.Feed.FeedSourceIframeComponent}
                rss_feed_url={rss_feed.url}
                selector={Map.get(rss_feed.selectors, @selected_category)}
                category={@selected_category}
                loading?={@iframe_loading?}
                safari_user_agent?={@safari_user_agent?}
              />
              <.feed_preview_component
                rss_feed_entries={rss_feed.entries}
                rss_feed_metadata={rss_feed.metadata}
                selector_colors={@selector_colors}
                loading?={@iframe_loading?}
                entries_content_loading?={@entries_content_loading?}
                highlight_headers={true}
              />
            </div>
            <%= unless @iframe_loading? do %>
              <.save_feed_button
                rss_feed_metadata={rss_feed.metadata}
                rss_feed_entries={rss_feed.entries}
              />
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, %{"user_agent" => user_agent}, socket) do
    {
      :ok,
      socket
      |> assign(
        selector_colors: %HtmlSelectors{
          entry_link_selector: "rgba(0, 0, 255, 0.2)",
          entry_published_at_selector: "rgba(0, 255, 0, 0.2)"
        }
      )
      |> assign(safari_user_agent?: UserAgent.safari_user_agent?(user_agent))
      |> assign(iframe_loading?: false)
      |> assign(entries_content_loading?: false)
      |> init_feed_search_session()
    }
  end

  defp init_feed_search_session(socket) do
    socket
    |> assign(selected_category: nil)
    |> assign(rss_feed: nil)
  end

  @impl true
  def handle_info({RssAutoGeneratorWeb.Feed.FeedUrlFormComponent, {:feed_url, url}}, socket),
    do: {
      :noreply,
      socket
      |> init_feed_search_session()
      |> assign(iframe_loading?: true)
      |> assign_rss_feed(url)
    }

  @impl true
  def handle_info(
        {RssAutoGeneratorWeb.Feed.FeedCategorySelector, {:category_selected, category}},
        socket
      ) do
    new_category = (category !== "" && category |> String.to_existing_atom()) || nil

    send_update(RssAutoGeneratorWeb.Feed.FeedSourceIframeComponent,
      id: "feed_iframe",
      event: :set_select_mode,
      payload: %{enabled: !!new_category}
    )

    {:noreply,
     socket
     |> assign(selected_category: new_category)}
  end

  @impl true
  def handle_info(
        {RssAutoGeneratorWeb.Feed.FeedSourceIframeComponent, {:item_clicked_selector, selector}},
        %{
          assigns: %{
            selected_category: selected_category,
            rss_feed: %{
              result: %{
                raw_html: rss_feed_raw_html
              }
            }
          }
        } = socket
      ) do
    {:noreply,
     assign_selector(
       socket,
       selector,
       selected_category,
       rss_feed_raw_html
     )}
  end

  @impl true
  def handle_info(
        {:entries_with_summary, entries_with_summary},
        %{
          assigns: %{
            rss_feed: %{
              result: rss_feed_result
            }
          }
        } = socket
      ) do
    {:noreply,
     socket
     |> assign(entries_content_loading?: false)
     |> assign(
       :rss_feed,
       update_async_result(
         rss_feed_result,
         %{
           entries: entries_with_summary
         }
       )
     )}
  end

  @impl true
  def handle_info(
        {RssAutoGeneratorWeb.Feed.FeedSourceIframeComponent, {:iframe_loaded}},
        %{
          assigns: %{
            selector_colors: selector_colors,
            rss_feed: %{
              result: %{
                selectors: selectors
              }
            }
          }
        } = socket
      ) do
    for {category, selector} <- selectors |> Map.to_list() do
      trigger_highlight_on_iframe(
        selector,
        category,
        selector_colors
      )
    end

    {:noreply, socket |> assign(iframe_loading?: false)}
  end

  defp assign_rss_feed(socket, rss_feed_url) do
    socket
    |> assign(rss_feed: AsyncResult.loading())
    |> assign(entries_content_loading?: true)
    |> assign_async(
      [:rss_feed],
      fn ->
        assign_rss_feed_async(socket, rss_feed_url)
      end
    )
  end

  defp assign_rss_feed_async(socket, rss_feed_url) do
    case HtmlParser.get_html_for_feed_parsers(rss_feed_url) do
      {:ok, rss_feed_raw_html} ->
        selectors = get_html_selectors(rss_feed_raw_html)
        rss_feed_metadata = MetadataParser.parse_feed_metadata(rss_feed_raw_html)

        entries =
          get_rss_feed_entries(
            rss_feed_raw_html,
            selectors,
            rss_feed_url,
            rss_feed_metadata.author,
            socket.root_pid
          )

        selectors = if Enum.count(entries) > 0, do: selectors, else: %HtmlSelectors{}

        {:ok,
         %{
           rss_feed: %{
             raw_html: rss_feed_raw_html,
             metadata: rss_feed_metadata,
             selectors: selectors,
             url: rss_feed_url,
             entries: entries,
             selectors_by: :llm
           }
         }}

      {:error, _} ->
        {:error, :html_not_found}
    end
  end

  defp get_html_selectors(html) do
    case LlmAnalyzer.get_html_selectors(html) do
      {:ok, selectors} ->
        selectors

      {:error, _} ->
        %HtmlSelectors{}
    end
  end

  defp trigger_highlight_on_iframe(selector, category, selector_colors) do
    send_update(RssAutoGeneratorWeb.Feed.FeedSourceIframeComponent,
      id: "feed_iframe",
      event: :trigger_highlight,
      payload: %{
        selector: selector,
        category: category,
        background_color: selector_colors |> Map.get(category)
      }
    )
  end

  defp assign_selector(
         %{
           assigns: %{
             selector_colors: selector_colors,
             rss_feed: %{
               result: %{
                 metadata: rss_feed_metadata,
                 url: rss_feed_url,
                 selectors: selectors
               }
             }
           }
         } =
           socket,
         selector,
         selected_category,
         rss_feed_raw_html
       ) do
    trigger_highlight_on_iframe(
      selector,
      selected_category,
      selector_colors
    )

    updated_selectors = Map.put(selectors, selected_category, selector)

    entries =
      get_rss_feed_entries(
        rss_feed_raw_html,
        updated_selectors,
        rss_feed_url,
        rss_feed_metadata.author,
        socket.root_pid
      )

    socket
    |> assign(entries_content_loading?: true)
    |> assign(
      :rss_feed,
      update_async_result(
        socket.assigns.rss_feed.result,
        %{
          selectors: updated_selectors,
          entries: entries,
          selectors_by: :user
        }
      )
    )
  end

  defp update_async_result(existing_result, update),
    do: AsyncResult.ok(Map.merge(existing_result, update))

  defp get_rss_feed_entries(rss_feed_raw_html, selectors, url, author, caller) do
    rss_feed_raw_html
    |> EntryParser.parse_feed_entries(selectors, url)
    |> maybe_add_author(author)
    |> add_content_async(caller)
  end

  defp maybe_add_author(items, nil), do: items

  defp maybe_add_author(items, author) do
    Enum.map(items, &Map.put(&1, :author, Map.get(&1, :author) || author))
  end

  defp add_content_async(items, caller) when is_list(items) do
    Task.start(fn ->
      items_with_summary =
        items
        |> Task.async_stream(
          &maybe_add_content_to_entry/1,
          max_concurrency: System.schedulers(),
          timeout: 60_000
        )
        |> Enum.map(fn {:ok, entry_with_summary} -> entry_with_summary end)

      send(caller, {:entries_with_summary, items_with_summary})
    end)

    items
  end

  defp maybe_add_content_to_entry(%Entry{link: link} = entry) do
    content =
      case HtmlParser.get_html_for_feed_parsers(link) do
        {:ok, item_html} ->
          MetadataParser.parse_feed_entry_content_summary(item_html)

        {:error, _} ->
          nil
      end

    entry
    |> Map.put(:content, content)
  end

  @impl true
  def handle_event(
        "save",
        _,
        %{
          assigns: %{
            rss_feed: %{
              result: %{
                metadata: rss_feed_metadata,
                selectors: selectors,
                entries: rss_feed_entries,
                url: rss_feed_url
              }
            }
          }
        } =
          socket
      ) do
    new_feed =
      Feeds.create_feed_with_entries(
        %{
          author: rss_feed_metadata.author,
          title: rss_feed_metadata.title,
          description: rss_feed_metadata.description,
          website_url: rss_feed_url,
          entry_link_selector: selectors.entry_link_selector,
          entry_published_at_selector: selectors.entry_published_at_selector
        },
        rss_feed_entries
        |> Enum.map(&Map.take(&1, [:title, :link, :published_at, :author, :content]))
      )

    case new_feed do
      {:ok, created_feed} ->
        {:noreply,
         socket
         |> put_flash(:info, "Feed saved successfully")
         |> init_feed_search_session()
         |> redirect(to: ~p"/feeds/#{created_feed}")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to save feed")}
    end
  end
end
