defmodule RssAutoGenerator.FeedHtmlParsers.EntryParserTest do
  use ExUnit.Case, async: true

  alias RssAutoGenerator.FeedAnalyzer.HtmlSelectors
  alias RssAutoGenerator.FeedHtmlParsers.EntryParser
  alias RssAutoGenerator.Entries.Entry

  describe "parse_feed_entries/3" do
    setup do
      html_with_nested_items = """
      <ul class="post-list">
        <li>
            <a href="/notes/replicate-vs-fly">
              <p>Replicate &amp; Fly cold-start latency</p>
            </a>
            <p>2024-02-16</p>
        </li>
        <li>
            <a href="/notes/leaving-at-the-cliff">
              <p>Leaving at the cliff</p>
            </a>
            <p>2024-01-31</p>
        </li>
      </ul>
      """

      html_with_flat_items = """
      <main>
        <time class="tl-date" datetime="2023-07-07">
          <a href="archive/2023/07/07.html">Fri 07 Jul 2023 </a>
        </time>
        <article>
          <h2 id="nix-shell-template">
            <a href="https://plurrrr.com/archive/2023/07/07.html#nix-shell-template">
              Nix shell template
            </a>
          </h2>
          <p>
            Source: <a href="https://paperless.blog/nix-shell-template">Nix shell template</a>, an article by Victor Engmark.
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
          <a href="archive/2023/07/06.html">Thu 06 Jul 2023</a>
        </time>
        <article>
          <h2 id="an-elegant-new-orchid-is-found-hiding-in-plain-sight">
            <a href="https://plurrrr.com/archive/2023/07/06.html#an-elegant-new-orchid-is-found-hiding-in-plain-sight">
              An elegant new orchid is found hiding in plain sight
            </a>
          </h2>
          <p>
            Source: <a href="https://phys.org/news/2023-03-elegant-orchid-plain-sight.html">An elegant new orchid is found hiding in plain sight</a>.
          </p>
        </article>
      </main>
      """

      html_with_anchor_container_items =
        """
          <section class="css-12g5xqg">
            <a class="css-ex1x9c" href="/blog/the-open-source-advantage/">
              <article class="css-nq19of">
                <div class="css-1rxdrkg">
                  <div class="css-hjj4xz">
                    <time>March 5, 2024</time>
                  </div>
                  <h2 class="css-1243ty6">
                    The Open Source Advantage: Strengthening Security Resilience Through Community Collaboration
                  </h2>
                  <p class="css-875zok">
                    This Q&amp;A features insights about open source collaboration, how it keeps organizations accountable, and how it differs from closed source protocols.
                  </p>
                </div>
              </article>
            </a>
            <a class="css-ex1x9c" href="/blog/bitwarden-design-updating-the-navigation-in-the-web-app/">
              <article class="css-nq19of">
                <div class="css-1rxdrkg">
                  <div class="css-hjj4xz">
                    <time>March 5, 2024</time>
                  </div>
                  <h2 class="css-1243ty6">Bitwarden Design: Updating the web app navigation</h2>
                  <p class="css-875zok">
                    The Bitwarden web app has received a new design! Read about the design choices and research behind the update in this blog.
                  </p>
                </div>
              </article>
            </a>
          </section>
        """

      %{
        html_with_nested_items: html_with_nested_items,
        html_with_flat_items: html_with_flat_items,
        html_with_anchor_container_items: html_with_anchor_container_items
      }
    end

    test "gets entries from nested html items", %{html_with_nested_items: html} do
      selectors = %HtmlSelectors{
        entry_link_selector: "ul > li > a > p",
        entry_published_at_selector: "ul > li > p"
      }

      url = "https://example.com"

      entries = EntryParser.parse_feed_entries(html, selectors, url)

      assert Enum.count(entries) == 2

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
        entry_link_selector: "ul > li > a > p"
      }

      url = "https://example.com"

      entries = EntryParser.parse_feed_entries(html, selectors, url)

      assert Enum.count(entries) == 2

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
        entry_link_selector: "main > article > h2 > a",
        entry_published_at_selector: "main > time > a"
      }

      url = "https://example.com"

      entries = EntryParser.parse_feed_entries(html, selectors, url)

      assert Enum.count(entries) == 3

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
               }
             ]
    end

    test "gets entries from flat html items without dates", %{html_with_flat_items: html} do
      selectors = %HtmlSelectors{
        entry_link_selector: "main > article > h2 > a"
      }

      url = "https://example.com"

      entries = EntryParser.parse_feed_entries(html, selectors, url)

      assert Enum.count(entries) == 3

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
               }
             ]
    end

    test "returns empty list when selectors are invalid", %{html_with_nested_items: html} do
      selectors = %HtmlSelectors{
        entry_link_selector: "foo",
        entry_published_at_selector: "bar"
      }

      url = "https://example.com"
      entries = EntryParser.parse_feed_entries(html, selectors, url)

      assert entries == []
    end

    test "gets entries from html with anchor container items", %{
      html_with_anchor_container_items: html
    } do
      selectors = %HtmlSelectors{
        entry_link_selector:
          "section.css-12g5xqg > a.css-ex1x9c > article.css-nq19of > div.css-1rxdrkg > h2.css-1243ty6",
        entry_published_at_selector:
          "section.css-12g5xqg > a.css-ex1x9c > article.css-nq19of > div.css-1rxdrkg > div.css-hjj4xz > time"
      }

      url = "https://example.com"

      entries = EntryParser.parse_feed_entries(html, selectors, url)
      assert Enum.count(entries) === 2

      assert entries == [
               %Entry{
                 title:
                   "The Open Source Advantage: Strengthening Security Resilience Through Community Collaboration",
                 link: "https://example.com/blog/the-open-source-advantage/",
                 published_at: ~U[2024-03-05 00:00:00Z]
               },
               %Entry{
                 title: "Bitwarden Design: Updating the web app navigation",
                 link:
                   "https://example.com/blog/bitwarden-design-updating-the-navigation-in-the-web-app/",
                 published_at: ~U[2024-03-05 00:00:00Z]
               }
             ]
    end

    test "handles browser implicit tbody tag" do
      html = """
        <table border="0" cellpadding="0" cellspacing="0">
          <tr class="athing" id="39637487">
            <td align="right" valign="top" class="title"><span class="rank">1.</span></td>
            <td class="title">
              <span class="titleline">
                <a href="https://lisyarus.github.io/blog/programming/2023/02/21/exponential-smoothing.html">
                  My favourite animation trick: exponential smoothing
                </a>
              </span>
            </td>
          </tr>
          <tr>
            <td colspan="2"></td>
            <td class="subtext">
              <span class="subline">
                <span class="score" id="score_39637487">128 points</span>
                by <a href="user?id=atan2" class="hnuser">atan2</a>
                <span class="age" title="2024-03-08T03:27:06">
                  <a href="item?id=39637487">2 hours ago</a>
                </span>
              </span>
            </td>
          </tr>
          <tr class="spacer" style="height:5px"></tr>
          <tr class="athing" id="39636991">
            <td align="right" valign="top" class="title"><span class="rank">2.</span></td>
            <td class="title">
              <span class="titleline">
                <a href="https://www.esa.int/Space_Safety/Space_Debris/Reentry_of_International_Space_Station_ISS_batteries_into_Earth_s_atmosphere">
                  Reentry of International Space Station Batteries into Earth's Atmosphere
                </a>
              </span>
            </td>
          </tr>
          <tr>
            <td colspan="2"></td>
            <td class="subtext">
              <span class="subline">
                <span class="score" id="score_39636991">84 points</span>
                by <a href="user?id=geox" class="hnuser">geox</a>
                <span class="age" title="2024-03-08T02:01:10">
                  <a href="item?id=39636991">3 hours ago</a>
                </span>
              </span>
            </td>
          </tr>
          <tr class="spacer" style="height:5px"></tr>
        </table>
      """

      selectors = %HtmlSelectors{
        entry_link_selector: "table > tbody > tr.athing > td.title > span.titleline > a",
        entry_published_at_selector:
          "table > tbody > tr > td.subtext > span.subline > span.age > a"
      }

      url = "https://example.com"

      entries = EntryParser.parse_feed_entries(html, selectors, url)
      assert Enum.count(entries) === 2

      assert entries == [
               %Entry{
                 title: "My favourite animation trick: exponential smoothing",
                 link:
                   "https://lisyarus.github.io/blog/programming/2023/02/21/exponential-smoothing.html"
               },
               %Entry{
                 title:
                   "Reentry of International Space Station Batteries into Earth's Atmosphere",
                 link:
                   "https://www.esa.int/Space_Safety/Space_Debris/Reentry_of_International_Space_Station_ISS_batteries_into_Earth_s_atmosphere"
               }
             ]
    end

    test "handles container classes that contain a." do
      html = """
      <div class="area block">
        <section class="block-post-listing layout-echo">
          <article class="post-summary post-summary--quinary">
            <a
              href="https://www.budgetbytes.com/make-soft-boiled-eggs/"
              aria-label="View How To Make Soft Boiled Eggs Recipe"
            >
              <div class="post-summary__content">
                <h2 class="post-summary__title"><span>How To Make Soft Boiled Eggs</span></h2>
              </div>
            </a>
          </article>
          <article class="post-summary post-summary--quinary">
            <a
              href="https://www.budgetbytes.com/stuffed-bell-peppers/"
              aria-label="View Stuffed Bell Peppers Recipe"
            >
              <div class="post-summary__content">
                <h2 class="post-summary__title"><span>Stuffed Bell Peppers</span></h2>
                <span class="cost-per">$12.21 recipe / $2.03 serving</span>
              </div>
            </a>
          </article>
        </section>
      </div>
      """

      selectors = %HtmlSelectors{
        entry_link_selector:
          "div.area.block > section.block-post-listing.layout-echo > article.post-summary.post-summary--quinary > a > div.post-summary__content > h2.post-summary__title > span"
      }

      url = "https://example.com"

      entries = EntryParser.parse_feed_entries(html, selectors, url)
      assert Enum.count(entries) === 2

      assert entries == [
               %Entry{
                 title: "How To Make Soft Boiled Eggs",
                 link: "https://www.budgetbytes.com/make-soft-boiled-eggs/"
               },
               %Entry{
                 title: "Stuffed Bell Peppers",
                 link: "https://www.budgetbytes.com/stuffed-bell-peppers/"
               }
             ]
    end
  end
end
