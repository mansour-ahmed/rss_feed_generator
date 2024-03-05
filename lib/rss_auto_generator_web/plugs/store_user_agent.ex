defmodule RssAutoGeneratorWeb.Plugs.StoreUserAgent do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _opts) do
    user_agent = get_req_header(conn, "user-agent") |> List.first()
    conn = put_session(conn, :user_agent, user_agent)
    conn
  end
end
