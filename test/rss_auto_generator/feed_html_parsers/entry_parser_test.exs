defmodule RssAutoGenerator.FeedHtmlParsers.EntryParserTest do
  use ExUnit.Case, async: true

  alias RssAutoGenerator.FeedAnalyzer.HtmlSelectors
  alias RssAutoGenerator.FeedHtmlParsers.EntryParser
  alias RssAutoGenerator.Entries.Entry

  describe "parse_feed_entries/3" do
    setup do
      html_with_nested_items = """
        <body>
          <div id="__next">
            <main class="__className_c0a04c">
              <div>
                <title>Notes</title>
                <h1>Notes</h1>
                <ul class="post-list">
                  <li>
                    <div>
                      <a href="/notes/replicate-vs-fly">
                        <p>Replicate &amp; Fly cold-start latency</p>
                      </a>
                      <p>2024-02-16</p>
                    </div>
                  </li>
                  <li>
                    <div>
                      <a href="/notes/leaving-at-the-cliff">
                        <p>Leaving at the cliff</p>
                      </a>
                      <p>2024-01-31</p>
                    </div>
                  </li>
                </ul>
              </div>
            </main>
          </div>
        </body>
      """

      html_with_flat_items = """
        <body>
          <div class="tl-page">
            <main>
              <time class="tl-date" datetime="2023-07-07">
                <a
                  href="archive/2023/07/07.html"
                  title="Nix shell template, IN vs. ANY, and Corinna in the Perl Core"
                >
                  Fri 07 Jul 2023
                </a>
              </time>
              <article>
                <h2 id="nix-shell-template">
                  <a href="https://plurrrr.com/archive/2023/07/07.html#nix-shell-template">
                    Nix shell template
                  </a>
                </h2>
                <p>
                  Source: <a href="https://paperless.blog/nix-shell-template">Nix shell
        template</a>, an article by
                  Victor Engmark.
                </p>
              </article>
              <article>
                <h2 id="til---in-is-not-the-same-as-any">
                  <a href="https://plurrrr.com/archive/2023/07/07.html#til---in-is-not-the-same-as-any">
                    TIL - IN is not the same as ANY
                  </a>
                </h2>
                <p>
                  Source: <a href="https://kmoppel.github.io/2023-07-04-til-in-is-not-the-same-as-any/">TIL - IN is not the same as
        ANY</a>,
                  an article by Kaarel Moppel.
                </p>
              </article>
              <time class="tl-date" datetime="2023-07-06">
                <a
                  href="archive/2023/07/06.html"
                  title="Elegant new orchid, Demystifying Text Data, and Image Upscaling"
                >
                  Thu 06 Jul 2023
                </a>
              </time>
              <article>
                <h2 id="an-elegant-new-orchid-is-found-hiding-in-plain-sight">
                  <a href="https://plurrrr.com/archive/2023/07/06.html#an-elegant-new-orchid-is-found-hiding-in-plain-sight">
                    An elegant new orchid is found hiding in plain sight
                  </a>
                </h2>
                <p>
                  Source: <a href="https://phys.org/news/2023-03-elegant-orchid-plain-sight.html">An elegant new orchid is found hiding in plain
        sight</a>.
                </p>
              </article>
              <article>
                <h2 id="demystifying-text-data-with-the-unstructured-python-library">
                  <a href="https://plurrrr.com/archive/2023/07/06.html#demystifying-text-data-with-the-unstructured-python-library">
                    Demystifying Text Data with the unstructured Python Library
                  </a>
                </h2>
                <p>
                  Source: <a href="https://saeedesmaili.com/demystifying-text-data-with-the-unstructured-python-library/">Demystifying Text Data with the unstructured Python Library
        (+alternatives)</a>,
                  an article by Saeed Esmaili.
                </p>
              </article>
              <article>
                <h2 id="image-upscaling-using-neural-networks">
                  <a href="https://plurrrr.com/archive/2023/07/06.html#image-upscaling-using-neural-networks">
                    Image Upscaling Using Neural Networks
                  </a>
                </h2>
                <p>
                  Source: <a href="https://boostpixels.com/image-upscaling-using-neural-networks">Image Upscaling Using Neural
        Networks</a>.
                </p>
              </article>
            </main>
          </div>
        </body>
      """

      %{
        html_with_nested_items: html_with_nested_items,
        html_with_flat_items: html_with_flat_items
      }
    end

    test "gets entries from nested html items", %{html_with_nested_items: html} do
      selectors = %HtmlSelectors{
        entry_link_selector: "body > div > main > div > ul > li > div > a > p",
        entry_published_at_selector: "body > div > main > div > ul > li > div > p"
      }

      url = "https://example.com"

      entries = EntryParser.parse_feed_entries(html, selectors, url)

      assert length(entries) == 2

      assert entries == [
               %Entry{
                 title: "Replicate & Fly cold-start latency",
                 link: "https://example.com/notes/replicate-vs-fly",
                 published_at: ~U[2024-02-16 00:00:00Z]
               },
               %Entry{
                 title: "Leaving at the cliff",
                 link: "https://example.com/notes/leaving-at-the-cliff",
                 published_at: ~U[2024-01-31 00:00:00Z]
               }
             ]
    end

    test "gets entries from nested html items without date selector", %{
      html_with_nested_items: html
    } do
      selectors = %HtmlSelectors{
        entry_link_selector: "body > div > main > div > ul > li > div > a > p"
      }

      url = "https://example.com"

      entries = EntryParser.parse_feed_entries(html, selectors, url)

      assert length(entries) == 2

      assert entries == [
               %Entry{
                 title: "Replicate & Fly cold-start latency",
                 link: "https://example.com/notes/replicate-vs-fly",
                 published_at: nil
               },
               %Entry{
                 title: "Leaving at the cliff",
                 link: "https://example.com/notes/leaving-at-the-cliff",
                 published_at: nil
               }
             ]
    end

    test "gets entries from flat html items", %{html_with_flat_items: html} do
      selectors = %HtmlSelectors{
        entry_link_selector: "body > div > main > article > h2 > a",
        entry_published_at_selector: "body > div > main > time > a"
      }

      url = "https://example.com"

      entries = EntryParser.parse_feed_entries(html, selectors, url)

      assert length(entries) == 5

      assert entries == [
               %Entry{
                 title: "Nix shell template",
                 link: "https://plurrrr.com/archive/2023/07/07.html#nix-shell-template",
                 published_at: ~U[2023-07-07 00:00:00Z]
               },
               %Entry{
                 title: "TIL - IN is not the same as ANY",
                 link:
                   "https://plurrrr.com/archive/2023/07/07.html#til---in-is-not-the-same-as-any",
                 published_at: ~U[2023-07-07 00:00:00Z]
               },
               %Entry{
                 title: "An elegant new orchid is found hiding in plain sight",
                 link:
                   "https://plurrrr.com/archive/2023/07/06.html#an-elegant-new-orchid-is-found-hiding-in-plain-sight",
                 published_at: ~U[2023-07-06 00:00:00Z]
               },
               %Entry{
                 title: "Demystifying Text Data with the unstructured Python Library",
                 link:
                   "https://plurrrr.com/archive/2023/07/06.html#demystifying-text-data-with-the-unstructured-python-library",
                 published_at: ~U[2023-07-06 00:00:00Z]
               },
               %Entry{
                 title: "Image Upscaling Using Neural Networks",
                 link:
                   "https://plurrrr.com/archive/2023/07/06.html#image-upscaling-using-neural-networks",
                 published_at: ~U[2023-07-06 00:00:00Z]
               }
             ]
    end

    test "gets entries from flat html items without dates", %{html_with_flat_items: html} do
      selectors = %HtmlSelectors{
        entry_link_selector: "body > div > main > article > h2 > a"
      }

      url = "https://example.com"

      entries = EntryParser.parse_feed_entries(html, selectors, url)

      assert length(entries) == 5

      assert entries == [
               %Entry{
                 title: "Nix shell template",
                 link: "https://plurrrr.com/archive/2023/07/07.html#nix-shell-template"
               },
               %Entry{
                 title: "TIL - IN is not the same as ANY",
                 link:
                   "https://plurrrr.com/archive/2023/07/07.html#til---in-is-not-the-same-as-any"
               },
               %Entry{
                 title: "An elegant new orchid is found hiding in plain sight",
                 link:
                   "https://plurrrr.com/archive/2023/07/06.html#an-elegant-new-orchid-is-found-hiding-in-plain-sight"
               },
               %Entry{
                 title: "Demystifying Text Data with the unstructured Python Library",
                 link:
                   "https://plurrrr.com/archive/2023/07/06.html#demystifying-text-data-with-the-unstructured-python-library"
               },
               %Entry{
                 title: "Image Upscaling Using Neural Networks",
                 link:
                   "https://plurrrr.com/archive/2023/07/06.html#image-upscaling-using-neural-networks"
               }
             ]
    end

    test "returns empty list when selectors are invalid", %{html_with_nested_items: html} do
      selectors = %HtmlSelectors{
        entry_link_selector: "body > div > foo",
        entry_published_at_selector: "body > div > bar"
      }

      url = "https://example.com"
      entries = EntryParser.parse_feed_entries(html, selectors, url)

      assert entries == []
    end
  end
end
