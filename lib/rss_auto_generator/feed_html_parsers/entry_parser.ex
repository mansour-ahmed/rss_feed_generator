defmodule RssAutoGenerator.FeedHtmlParsers.EntryParser do
  @moduledoc """
  Responsible for parsing the HTML content of a page and extracting the RSS feed items from it.
  """

  alias RssAutoGenerator.FeedAnalyzer.HtmlSelectors
  alias RssAutoGenerator.Utils.{Url, Date}
  alias RssAutoGenerator.Entries.Entry

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
      |> Enum.filter(fn {_, value} ->
        !!value &&
          document
          |> Floki.find(value)
          |> Enum.count() > 0
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
    {container_selector, link_selector, published_at_selector} =
      find_common_parent_and_child_selectors(
        entry_link_selector,
        entry_published_at_selector
      )

    anchor_element_selector = find_anchor_selector(link_selector)

    document
    |> Floki.find(container_selector)
    |> Enum.flat_map(fn container_node ->
      parse_full_entries(
        container_node,
        link_selector,
        published_at_selector,
        anchor_element_selector,
        url
      )
    end)
  end

  defp parse_document(
         document,
         %HtmlSelectors{
           entry_link_selector: link_selector
         },
         url
       )
       when is_binary(link_selector) and link_selector !== "" do
    anchor_element_selector = find_anchor_selector(link_selector)

    document
    |> Floki.find(anchor_element_selector)
    |> Enum.map(fn container_node ->
      %Entry{
        title: get_text_from_node(container_node),
        link: get_href_from_node(container_node, url)
      }
    end)
  end

  defp parse_document(_, _selectors, _url), do: []

  defp find_anchor_selector(selector) do
    parts = String.split(selector, ">")
    index = Enum.find_index(parts, fn part -> part === " a " end) || Enum.count(parts) - 1
    taken = Enum.take(parts, (Enum.count(parts) > 2 && index + 1) || index)
    Enum.join(taken, ">")
  end

  defp find_common_parent_and_child_selectors(selector1, selector2)
       when is_binary(selector1) and is_binary(selector2) do
    parts1 = String.split(selector1, " > ")
    parts2 = String.split(selector2, " > ")

    {common_parent_parts, child_selector1_parts, child_selector2_parts} =
      find_common_and_child_parts(parts1, parts2, [], [], [])

    common_parent = Enum.join(common_parent_parts, " > ")
    child_selector1 = Enum.join(child_selector1_parts, " > ")
    child_selector2 = Enum.join(child_selector2_parts, " > ")

    {common_parent, child_selector1, child_selector2}
  end

  defp find_common_parent_and_child_selectors(selector1, selector2),
    do: {nil, selector1, selector2}

  defp find_common_and_child_parts([], parts2, common, child1, _child2),
    do: {common, child1, parts2}

  defp find_common_and_child_parts(parts1, [], common, _child1, child2),
    do: {common, parts1, child2}

  defp find_common_and_child_parts([head1 | tail1], [head2 | tail2], common, child1, child2) do
    if head1 == head2 do
      find_common_and_child_parts(tail1, tail2, common ++ [head1], child1, child2)
    else
      {common, [head1 | tail1], [head2 | tail2]}
    end
  end

  defp parse_full_entries(el, link_selector, published_at_selector, anchor_element_selector, url) do
    if entry_wrapped_by_container?(el, link_selector, published_at_selector) do
      [
        parse_rss_entry_from_container(
          el,
          link_selector,
          published_at_selector,
          anchor_element_selector,
          url
        )
      ]
    else
      parse_rss_entries_from_document(
        el,
        link_selector,
        published_at_selector,
        anchor_element_selector,
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

  defp parse_rss_entry_from_container(
         container_element,
         title_selector,
         date_selector,
         link_selector,
         base_url
       ) do
    {container_tag, _, _} = container_element

    %Entry{
      title: get_text_by_selector(container_element, "#{container_tag} > #{title_selector}"),
      link:
        get_url_by_selector(container_element, "#{container_tag} > #{link_selector}", base_url),
      published_at:
        container_element
        |> get_text_by_selector("#{container_tag} > #{date_selector}")
        |> Date.parse_datetime()
    }
  end

  defp parse_rss_entries_from_document(
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
        title_selector,
        date_selector
      )

    Enum.flat_map(article_nodes_by_date, fn {date, articles} ->
      published_at =
        date
        |> get_text_by_selector(date_selector)
        |> Date.parse_datetime()

      Enum.map(articles, fn article ->
        %Entry{
          title: get_text_by_selector(article, title_selector),
          link: get_url_by_selector(article, link_selector, url),
          published_at: published_at
        }
      end)
    end)
  end

  defp group_articles_by_date(document_nodes, title_selector, date_selector) do
    title_tag =
      title_selector
      |> String.split(" > ")
      |> hd()

    date_tag =
      date_selector
      |> String.split(" > ")
      |> hd()

    {last_articles_batch, last_known_date, groups} =
      document_nodes
      |> Enum.reduce({[], nil, []}, fn
        {^date_tag, _, _} = date, {articles, current_date, article_groups} ->
          article_groups = get_article_groups(articles, current_date, article_groups)
          {[], date, article_groups}

        {^title_tag, _, _} = new_article, {articles, current_date, article_groups} ->
          {[new_article | articles], current_date, article_groups}

        _, state ->
          state
      end)

    last_articles_batch
    |> get_article_groups(last_known_date, groups)
    |> Enum.reverse()
  end

  defp get_article_groups(articles, current_date, article_groups)
       when not is_nil(current_date) and articles !== [] do
    [{current_date, Enum.reverse(articles)} | article_groups]
  end

  defp get_article_groups(_articles, _current_date, article_groups), do: article_groups

  defp get_text_by_selector(document, selector) do
    document
    |> Floki.find(selector)
    |> get_text_from_node()
  end

  defp get_text_from_node(node) do
    node
    |> Floki.text(deep: true)
    |> String.trim()
  end

  defp get_url_by_selector(document, selector, base_url) do
    document
    |> Floki.find(selector)
    |> get_href_from_node(base_url)
  end

  defp get_href_from_node(node, base_url) do
    node
    |> Floki.attribute("href")
    |> Enum.at(0)
    |> Url.get_absolute_url(base_url)
  end
end
