defmodule KgkmWeb.TopNav do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  # Como você usa Phoenix, se precisar das rotas ~p certifique-se de importar as macros corretas do seu_app_web
  use KgkmWeb, :html

  def nav(assigns) do
    ~H"""
    <.hamburger_button />
    <.top_nav_content />
    <.open_hamburger />
    """
  end

  defp top_nav_content(assigns) do
    ~H"""
    <div class="hidden md:flex items-center">
      <ul class="flex flex-row items-center gap-6 list-none p-0 m-0">
        <li>
          <.link
            href={~p"/chats"}
            class="text-zinc-500 dark:text-zinc-400 font-medium text-sm hover:text-zinc-900 dark:hover:text-zinc-100 transition-colors"
          >
            Home
          </.link>
        </li>
      </ul>
    </div>
    """
  end

  defp hamburger_button(assigns) do
    ~H"""
    <div class="block md:hidden">
      <button
        class="flex items-center justify-center bg-transparent border-none cursor-pointer p-0 text-zinc-900 dark:text-zinc-100"
        phx-click={show_hamburger()}
      >
        <.icon name="hero-bars-4" class="h-6 w-6" />
      </button>
    </div>
    """
  end

  defp open_hamburger(assigns) do
    ~H"""
    <div id="hamburger-container" class="hidden fixed inset-0 z-50">
      <%!-- Backdrop escuro com fechar ao clicar --%>
      <div
        id="hamburger-backdrop"
        class="hidden absolute inset-0 bg-black/50 backdrop-blur-xs"
        phx-click={hide_hamburger()}
      >
      </div>

      <%!-- Sidebar content --%>
      <nav
        id="hamburger-content"
        class="hidden absolute top-0 left-0 h-full w-4/5 max-w-xs bg-white dark:bg-zinc-900 border-r border-zinc-200 dark:border-zinc-800 flex-col overflow-y-auto shadow-2xl box-border"
      >
        <div class="flex items-center justify-between p-4 border-b border-zinc-200 dark:border-zinc-800">
          <div class="flex items-center gap-3">
            <a href={~p"/"} class="flex items-center">
              <img src={~p"/images/logo.svg"} width="32" height="32" alt="Logo" />
            </a>
            <p class="bg-blue-500/10 text-blue-500 rounded-lg px-2 py-0.5 font-semibold text-sm m-0">
              KGKM
            </p>
          </div>
          <button
            phx-click={hide_hamburger()}
            class="text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300"
          >
            <.icon name="hero-x-mark" class="h-5 w-5" />
          </button>
        </div>

        <div class="flex-1 py-2">
          <ul class="list-none p-0 m-0">
            <li>
              <.link
                href={~p"/chats"}
                class="block px-5 py-3 text-base font-medium text-zinc-900 dark:text-zinc-100 border-b border-zinc-100 dark:border-zinc-800/50 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors"
              >
                Home
              </.link>
            </li>
            <li>
              <.link
                href={~p"/users/settings"}
                class="block px-5 py-3 text-base font-medium text-zinc-900 dark:text-zinc-100 border-b border-zinc-100 dark:border-zinc-800/50 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors"
              >
                Settings
              </.link>
            </li>
          </ul>
        </div>
      </nav>
    </div>
    """
  end

  defp show_hamburger(js \\ %JS{}) do
    js
    |> JS.show(to: "#hamburger-container")
    |> JS.show(
      to: "#hamburger-backdrop",
      transition: {"transition-opacity ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "#hamburger-content",
      transition:
        {"transition-transform ease-out duration-300", "-translate-x-full", "translate-x-0"},
      display: "flex"
    )
    |> JS.add_class("overflow-hidden", to: "body")
  end

  defp hide_hamburger(js \\ %JS{}) do
    js
    |> JS.hide(
      to: "#hamburger-backdrop",
      transition: {"transition-opacity ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "#hamburger-content",
      transition:
        {"transition-transform ease-in duration-200", "translate-x-0", "-translate-x-full"}
    )
    |> JS.hide(to: "#hamburger-container", time: 200)
    |> JS.remove_class("overflow-hidden", to: "body")
  end
end
