defmodule RssAutoGeneratorWeb.Layouts do
  use RssAutoGeneratorWeb, :html

  def app(assigns) do
    ~H"""
    <header class="p-2 sm:py-3 sm:px-10 flex flex-row items-center justify-between">
      <.link href={~p"/"}>
        <img src="/images/logo.png" alt="App Logo" class="w-20 sm:w-24" />
      </.link>
      <ul class="relative flex flex-wrap items-center gap-4 sm:gap-8 px-4 sm:px-6 lg:px-8 sm:justify-end">
        <li>
          <.header_link href={~p"/feeds"}>
            Feeds
          </.header_link>
        </li>
      </ul>
    </header>
    <main class="min-h-[calc(100vh_-_20rem)]">
      <div class="mx-auto max-w-screen-xl px-4">
        <.flash_group flash={@flash} />
        <div class="pt-4 px-5">
          <%= @inner_content %>
        </div>
      </div>
    </main>
    <.footer />
    """
  end

  attr :method, :string, default: "get", values: ["get", "post", "put", "patch", "delete"]
  attr :href, :string, required: true
  slot :inner_block

  defp header_link(assigns) do
    ~H"""
    <.link
      href={@href}
      method={@method}
      class="text-xl sm:text-2xl leading-6 border-b-yellow-500 border-b-2 border-spacing-6 hover:text-yellow-600"
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp footer(assigns) do
    ~H"""
    <footer class="flex flex-row items-center justify-center gap-8 px-2  pt-12 sm:pt-24 pb-6">
      <aside>
        Created by Ahmed Mansour
      </aside>
      <img src="/images/signature.jpg" class="w-28" alt="Ahmed's signature Logo" />
    </footer>
    """
  end

  embed_templates "layouts/*"
end
