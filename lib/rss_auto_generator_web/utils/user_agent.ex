defmodule RssAutoGeneratorWeb.Utils.UserAgent do
  def safari_user_agent?(user_agent) do
    user_agent
    |> String.split(" ")
    |> Enum.reverse()
    |> hd()
    |> String.contains?("Safari/60")
  end
end
