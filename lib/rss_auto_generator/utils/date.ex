defmodule RssAutoGenerator.Utils.Date do
  @doc """
  Parses an unstructured date string into a DateTime struct.
  """
  def parse_datetime(date) do
    case DateTimeParser.parse_datetime(date, assume_time: true, assume_utc: true) do
      {:ok, date} ->
        date

      _ ->
        nil
    end
  end
end
