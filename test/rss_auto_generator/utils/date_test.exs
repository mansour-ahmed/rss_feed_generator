defmodule RssAutoGenerator.Utils.DateTest do
  use ExUnit.Case, async: true

  alias RssAutoGenerator.Utils.Date

  describe "parse_datetime/1" do
    test "parses a date string into a DateTime struct" do
      assert ~U[2020-01-01 00:00:00Z] == Date.parse_datetime("2020-01-01T00:00:00Z")
      assert ~U[2024-02-16 00:00:00Z] == Date.parse_datetime("2024-02-16")
      assert ~U[2023-07-06 00:00:00Z] == Date.parse_datetime("Thu 06 Jul 2023")
    end

    test "parses an invalid date string returns nil" do
      date = "invalid date"

      assert nil == Date.parse_datetime(date)
    end
  end

  describe "format_date/1" do
    test "formats a date into a string" do
      date = ~U[2020-01-01 00:00:00Z]

      assert "2020-01-01" == Date.format_date(date)
    end
  end
end
