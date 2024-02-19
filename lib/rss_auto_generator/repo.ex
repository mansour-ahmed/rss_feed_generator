defmodule RssAutoGenerator.Repo do
  use Ecto.Repo,
    otp_app: :rss_auto_generator,
    adapter: Ecto.Adapters.Postgres
end
