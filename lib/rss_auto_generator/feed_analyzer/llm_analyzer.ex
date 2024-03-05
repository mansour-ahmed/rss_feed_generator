defmodule RssAutoGenerator.FeedAnalyzer.LlmAnalyzer do
  alias RssAutoGenerator.FeedAnalyzer.HtmlSelectors

  def get_html_selectors(html) do
    max_length = 65_536

    if String.length(html) > max_length do
      {:error, "HTML content is too large to be analyzed"}
    else
      try do
        Instructor.chat_completion(
          model: "gpt-3.5-turbo",
          response_model: HtmlSelectors,
          validation_context: %{
            raw_html: html
          },
          max_retries: 3,
          messages: [
            %{
              role: "system",
              content: """
              Your task is to analyze the provided HTML content to identify and extract HTML selectors compatible with Elixir's Floki library.
              These selectors will be used to extract RSS feed items for inclusion in an RSS feed.
              Ensure that the selectors are precisely tailored to capture the correct elements within the HTML structure and are as robust as possible to accommodate future changes in the HTML structure.
              Selectors can include both HTML elements and CSS classes. Avoid using IDs in the selectors unless necessary.
              When referencing CSS classes, the selector should always specify the corresponding HTML element, for example, div.container rather than simply .container.
              Selectors must always trace a path from the root HTML element to the desired element, e.g., body > main.container > ul.list.pb2 > li > p > a.
              Selectors must be valid based on the given HTML content. Selectors are only selecting the item link and the published date. Don't worry about the actualy content of the rss feed items.
              """
            },
            %{
              role: "user",
              content: """
              Provide the necessary selectors that would be most suitable for extracting RSS feed items from the following HTML:
              ```
              #{html}
              ```
              """
            }
          ]
        )
      catch
        _ -> {:error, "Failed to analyze HTML content"}
      end
    end
  end
end
