defmodule RssAutoGenerator.FeedHtmlParsers.EntryParserUtils do
  alias RssAutoGenerator.Utils.Url

  def selector_has_matches?(nil, _), do: false

  def selector_has_matches?(selector, document),
    do:
      document
      |> Floki.find(selector)
      |> Enum.count() > 0

  @doc """
  Removes the implicit tbody element that browsers add to the DOM when parsing HTML.
  """
  def remove_browser_implicit_tbody(nil, _), do: nil

  def remove_browser_implicit_tbody(selector, document) do
    parts_without_tbody = selector |> String.split("> tbody >")

    parts_without_tbody
    |> Enum.reduce([], fn part, acc ->
      matches_with_tbody = Floki.find(document, part <> "> tbody")

      part =
        if Enum.count(matches_with_tbody) > 0 do
          part <> " tbody >"
        else
          part
        end

      [part | acc]
    end)
    |> Enum.reverse()
    |> join_selector_parts()
  end

  def get_text_by_selector(document, selector) do
    element =
      if selector === "",
        do: document,
        else:
          document
          |> Floki.find(selector)

    get_text_from_node(element)
  end

  def get_text_from_node(node) do
    node
    |> Floki.text(deep: true)
    |> String.trim()
  end

  def get_url_by_selector(document, selector, base_url) do
    document
    |> Floki.find(selector)
    |> get_href_from_node(base_url)
  end

  def get_href_from_node(node, base_url) do
    node
    |> Floki.find("a")
    |> Floki.attribute("href")
    |> Enum.at(0)
    |> Url.get_absolute_url(base_url)
  end

  def find_anchor_selector_and_title_selector(selector) do
    parts = get_selector_parts(selector)

    index =
      Enum.find_index(parts, fn part -> part === "a" || String.starts_with?(part, "a.") end) ||
        Enum.count(parts) - 1

    anchor_parts_index = index + 1
    parts_length = Enum.count(parts)
    taken = Enum.take(parts, anchor_parts_index)
    rest_of_parts = Enum.slice(parts, anchor_parts_index..parts_length)

    anchor_selector = join_selector_parts(taken)
    title_selector = join_selector_parts(rest_of_parts)

    {anchor_selector, title_selector}
  end

  def find_common_parent_and_child_selectors(selector1, selector2)
      when is_binary(selector1) and is_binary(selector2) do
    parts1 = get_selector_parts(selector1)
    parts2 = get_selector_parts(selector2)

    {common_parent_parts, child_selector1_parts, child_selector2_parts} =
      find_common_and_child_parts(parts1, parts2, [], [], [])

    common_parent = join_selector_parts(common_parent_parts)
    child_selector1 = join_selector_parts(child_selector1_parts)
    child_selector2 = join_selector_parts(child_selector2_parts)

    {common_parent, child_selector1, child_selector2}
  end

  def find_common_parent_and_child_selectors(selector1, selector2),
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

  defp get_selector_parts(selector), do: String.split(selector, " > ")
  defp join_selector_parts(parts), do: Enum.join(parts, " > ")
end
