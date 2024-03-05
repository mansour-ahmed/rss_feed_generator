defmodule RssAutoGenerator.FeedHtmlParsers.EntryParser do
  @moduledoc """
  Responsible for parsing the HTML content of a page and extracting the RSS feed items from it.
  """

  alias RssAutoGenerator.FeedAnalyzer.HtmlSelectors
  alias RssAutoGenerator.Utils.Date
  alias RssAutoGenerator.Entries.Entry
  alias RssAutoGenerator.FeedHtmlParsers.EntryParserUtils

  @doc """
  Parses the HTML content of a page and extracts the RSS feed items from it.
  Feed items are extracted based on the provided selectors.

  ## Examples

      iex> RssFeedHtmlParser.parse_feed_entries(html_content, selectors, base_url)
      [
        %Entry{
          title: "Replicate & Fly cold-start latency",
          link: "https://example.com/notes/replicate-vs-fly",
          published_at: "2024-02-16"
        },
        %Entry{
          title: "Leaving at the cliff",
          link: "https://example.com/notes/leaving-at-the-cliff",
          published_at: "2024-01-31"
        }
      ]
  """
  def parse_feed_entries(html_content, %HtmlSelectors{} = selectors, base_url) do
    case Floki.parse_document(html_content) do
      {:ok, document} ->
        valid_selectors = get_valid_selectors(selectors, document)
        parse_document(document, valid_selectors, base_url)

      _error ->
        []
    end
  end

  defp get_valid_selectors(selectors, document) do
    valid_selectors =
      selectors
      |> Map.from_struct()
      |> Map.to_list()
      |> Enum.map(fn {key, value} ->
        {key, EntryParserUtils.remove_browser_implicit_tbody(value, document)}
      end)
      |> Enum.filter(fn {_, value} ->
        EntryParserUtils.selector_has_matches?(value, document)
      end)

    struct(HtmlSelectors, valid_selectors)
  end

  defp parse_document(
         document,
         %HtmlSelectors{
           entry_link_selector: entry_link_selector,
           entry_published_at_selector: entry_published_at_selector
         },
         url
       )
       when is_binary(entry_link_selector) and is_binary(entry_published_at_selector) and
              entry_link_selector !== "" and entry_published_at_selector !== "" do
    {anchor_element_selector, title_element_selector} =
      EntryParserUtils.find_anchor_selector_and_title_selector(entry_link_selector)

    {container_selector, link_selector, published_at_selector} =
      EntryParserUtils.find_common_parent_and_child_selectors(
        anchor_element_selector,
        entry_published_at_selector
      )

    if container_selector !== "" do
      document
      |> Floki.find(container_selector)
      |> Enum.flat_map(fn container_node ->
        parse_entries(
          container_node,
          link_selector,
          published_at_selector,
          title_element_selector,
          url
        )
      end)
    else
      parse_document(document, %HtmlSelectors{entry_link_selector: link_selector}, url)
    end
  end

  defp parse_document(
         document,
         %HtmlSelectors{
           entry_link_selector: link_selector
         },
         url
       )
       when is_binary(link_selector) and link_selector !== "" do
    {anchor_element_selector, title_element_selector} =
      EntryParserUtils.find_anchor_selector_and_title_selector(link_selector)

    document
    |> Floki.find(anchor_element_selector)
    |> Enum.map(fn element ->
      %Entry{
        title: EntryParserUtils.get_text_by_selector(element, title_element_selector),
        link: EntryParserUtils.get_href_from_node(element, url)
      }
    end)
  end

  defp parse_document(_, _selectors, _url), do: []

  defp parse_entries(el, link_selector, published_at_selector, title_selector, url) do
    link_is_container? = link_selector === ""

    entry_wrapped_by_container? =
      entry_wrapped_by_container?(el, link_selector, published_at_selector)

    if entry_wrapped_by_container? || link_is_container? do
      [
        parse_entry_with_container(
          el,
          url,
          title_selector,
          link_selector,
          published_at_selector
        )
      ]
    else
      parse_entries_without_container(
        el,
        title_selector,
        published_at_selector,
        link_selector,
        url
      )
    end
  end

  defp entry_wrapped_by_container?(container_element, title_selector, date_selector) do
    {tag, _, _} = container_element

    title_count =
      container_element
      |> Floki.find("#{tag} > #{title_selector}")
      |> Enum.count()

    dates_count =
      container_element
      |> Floki.find("#{tag} > #{date_selector}")
      |> Enum.count()

    title_count === 1 and dates_count === 1
  end

  defp parse_entry_with_container(
         container_element,
         base_url,
         title_selector,
         link_selector,
         date_selector
       ) do
    {container_tag, _, _} = container_element

    title_selector =
      if title_selector !== "",
        do: "#{link_selector} > #{title_selector}",
        else: link_selector

    %Entry{
      title: EntryParserUtils.get_text_by_selector(container_element, title_selector),
      link: EntryParserUtils.get_href_from_node(container_element, base_url),
      published_at:
        container_element
        |> EntryParserUtils.get_text_by_selector("#{container_tag} > #{date_selector}")
        |> Date.parse_datetime()
    }
  end

  defp parse_entries_without_container(
         document,
         title_selector,
         date_selector,
         link_selector,
         url
       ) do
    article_nodes_by_date =
      document
      |> Floki.children()
      |> group_articles_by_date(
        link_selector,
        date_selector
      )

    Enum.flat_map(article_nodes_by_date, fn {date, articles} ->
      published_at =
        date
        |> EntryParserUtils.get_text_by_selector(date_selector)
        |> Date.parse_datetime()

      Enum.map(articles, fn article ->
        title_selector =
          if title_selector !== "",
            do: "#{link_selector} >  #{title_selector}",
            else: link_selector

        %Entry{
          title:
            EntryParserUtils.get_text_by_selector(
              article,
              title_selector
            ),
          link: EntryParserUtils.get_url_by_selector(article, link_selector, url),
          published_at: published_at
        }
      end)
    end)
  end

  defp group_articles_by_date(document_nodes, title_selector, date_selector) do
    {last_articles_batch, last_known_date, groups} =
      document_nodes
      |> Enum.reduce(
        {[], nil, []},
        fn
          element, {articles, current_date, article_groups} ->
            published_at? = Floki.find(element, date_selector) !== []
            title? = Floki.find(element, title_selector) !== []

            cond do
              published_at? ->
                group_date = current_date || element
                article_groups = get_article_groups(articles, group_date, article_groups)
                {[], element, article_groups}

              title? ->
                {[element | articles], current_date, article_groups}

              true ->
                {articles, current_date, article_groups}
            end
        end
      )

    last_articles_batch
    |> get_article_groups(last_known_date, groups)
    |> Enum.reverse()
  end

  defp get_article_groups(articles, current_date, article_groups)
       when not is_nil(current_date) and articles !== [],
       do: [{current_date, Enum.reverse(articles)} | article_groups]

  defp get_article_groups(_articles, _current_date, article_groups), do: article_groups
end
