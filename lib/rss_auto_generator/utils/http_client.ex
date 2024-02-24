defmodule RssAutoGenerator.Utils.HttpClient do
  def get_req(url, headers \\ [], timeout \\ 30_000) do
    :get
    |> Finch.build(
      url,
      headers
    )
    |> Finch.request(RssAutoGenerator.Finch, receive_timeout: timeout)
  end
end
