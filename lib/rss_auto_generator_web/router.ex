defmodule RssAutoGeneratorWeb.Router do
  use RssAutoGeneratorWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RssAutoGeneratorWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers,
         %{
           "content-security-policy" =>
             "default-src 'self'; frame-src 'self'; style-src * 'unsafe-inline'; img-src * data:; object-src 'none';",
           "x-xss-protection" => "1; mode=block"
         }
  end

  scope "/", RssAutoGeneratorWeb do
    pipe_through :browser

    live "/", HomeLive.Index, :rss

    get "/proxy", ProxyHtmlController, :proxy_html
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:rss_auto_generator, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RssAutoGeneratorWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
