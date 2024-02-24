defmodule RssAutoGenerator.FeedHtmlParsers.MetadataParserTest do
  use ExUnit.Case, async: true

  alias RssAutoGenerator.FeedHtmlParsers.MetadataParser

  describe "parse_feed_metadata/1" do
    test "parses description from html content" do
      assert %{description: "Example description"} =
               MetadataParser.parse_feed_metadata("""
                 <meta name="description" content="Example description">
               """)

      assert %{description: "Example og description"} =
               MetadataParser.parse_feed_metadata("""
                 <meta property="og:description" content="Example og description">
               """)

      assert %{description: "Example twitter description"} =
               MetadataParser.parse_feed_metadata("""
                 <meta name="twitter:description" content="Example twitter description">
               """)
    end

    test "parses author from html content" do
      assert %{author: "Example author"} =
               MetadataParser.parse_feed_metadata("""
                 <meta name="author" content="Example author">
               """)

      assert %{author: "Example twitter creator"} =
               MetadataParser.parse_feed_metadata("""
                 <meta name="twitter:creator" content="Example twitter creator">
               """)

      assert %{author: "Example book author"} =
               MetadataParser.parse_feed_metadata("""
                 <meta property="book:author" content="Example book author">
               """)
    end

    test "parses title from html content" do
      assert %{title: "Example title"} =
               MetadataParser.parse_feed_metadata("""
                 <meta property="og:title" content="Example title">
               """)

      assert %{title: "Example twitter title"} =
               MetadataParser.parse_feed_metadata("""
                 <meta name="twitter:title" content="Example twitter title">
               """)

      assert %{title: "Example title"} =
               MetadataParser.parse_feed_metadata("""
                 <title>Example title</title>
               """)
    end
  end
end
