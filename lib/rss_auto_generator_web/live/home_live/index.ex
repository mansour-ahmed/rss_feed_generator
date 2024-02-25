defmodule RssAutoGeneratorWeb.HomeLive.Index do
  use RssAutoGeneratorWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="sm:pt-32">
      <div class="flex sm:flex-row flex-col justify-center items-center sm:justify-between gap-10 sm:gap-20">
        <div class="flex flex-col sm:items-start items-center gap-10 sm:gap-12">
          <h1 class="text-3xl sm:text-5xl sm:leading-normal text-zinc-700 font-bold text-center sm:text-left">
            Create A RSS Feed From
            <.highlight_text>Any Website</.highlight_text>
          </h1>
          <.link href={~p"/feeds/new"}>
            <button class="text-lg sm:text-xl font-semibold text-yellow-800 bg-yellow-50 rounded-lg p-3 sm:p-4 ring-1 ring-inset ring-yellow-600/20  hover:bg-yellow-100">
              Add your feed now
            </button>
          </.link>
        </div>
        <div class="max-w-[20rem] sm:max-w-[30rem]">
          <.blob_container>
            <img src="/images/landing_card.png" alt="App Logo" class="w-full" />
          </.blob_container>
        </div>
      </div>
    </div>
    """
  end

  slot(:inner_block, required: true)

  def blob_container(assigns) do
    ~H"""
    <div class="flex w-full group">
      <img
        src={~s(images/blob-yellow.svg)}
        class="mr-[-100%] w-full ease-out duration-300 group-hover:scale-105"
      />
      <div class="w-[calc(100%_-_1.5rem)] self-center rounded-lg overflow-hidden sm:w-[calc(100%_-_5rem)] z-10">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
