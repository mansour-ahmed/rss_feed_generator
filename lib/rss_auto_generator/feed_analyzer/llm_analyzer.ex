defmodule RssAutoGenerator.FeedAnalyzer.LlmAnalyzer do
  alias RssAutoGenerator.FeedAnalyzer.HtmlSelectors

  def get_html_selectors(html) do
    try do
      Instructor.chat_completion(
        model: "gpt-3.5-turbo",
        response_model: HtmlSelectors,
        max_retries: 3,
        messages: [
          %{
            role: "user",
            content: """
            Your task is to analyze the provided HTML content to identify and extract HTML selectors compatible with Elixir's Floki library.
            These selectors will be used to extract RSS feed items for inclusion in an RSS feed.
            Ensure that the selectors are precisely tailored to capture the correct elements within the HTML structure and are as robust as possible to accommodate future changes in the HTML structure.
            Selectors should consist only of HTML elements and must trace a path from the root HTML element to the desired element, e.g., body > main > ul > li > p > a. Do not include any classes or ids in the selectors.
            Please provide the necessary selectors that would be most suitable for extracting RSS feed items from the following HTML:
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
