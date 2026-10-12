defmodule KgkmWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use KgkmWeb, :html
  alias KgkmWeb.TopNav
  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates("layouts/*")

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")

  attr(:current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"
  )

  #  NOVA ATRIBUTO: Permite ocultar a BottomNav e remover o padding inferior extra
  attr(:hide_bottom_nav, :boolean,
    default: false,
    doc: "whether to hide bottom navigation bar and adjust bottom padding"
  )

  slot(:inner_block, required: true)

  def app(assigns) do
    ~H"""
    <header class="w-full flex items-center justify-between px-4 sm:px-6 lg:px-8 h-16 border-b border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 flex-shrink-0 z-40">
      <div class="flex-items-center col-start-1">
        <TopNav.nav />
      </div>
      <div class="flex items-center min-w-0 col-start-2 md:ml-auto md:mr-4">
        <.live_component module={KgkmWeb.LocationNav} id="global-location-picker" />
      </div>
      <!-- Menu usuário (apenas desktop) -->
      <div class="flex items-center gap-4">
        <.theme_toggle />
        <%= if @current_scope do %>
          <.link href={~p"/users/notifications"}>
            <.icon name="hero-bell" class="w-6 h-6" />
          </.link>
        <% end %>
        <ul class="hidden md:flex items-center gap-6 list-none p-0 m-0 text-sm font-medium">
          <%= if @current_scope do %>
            <.link href={~p"/users/settings"}>
              <div class="flex flex-col items-center justify-center my-8 gap-4">
                <div class="relative group w-8 h-8">
                  <div class="w-full h-full rounded-full overflow-hidden border-1 border-orange-500 dark:border-blue-600 shadow-md bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center relative">
                    <img
                      src={
                        @current_scope.user.avatar_url ||
                          "https://api.dicebear.com/7.x/bottts/svg?seed=#{@current_scope.user.email}"
                      }
                      class="w-full h-full object-cover"
                    />
                  </div>
                </div>
              </div>
            </.link>
          <% else %>
            <li>
              <.link
                href={~p"/users/register"}
                class="text-zinc-600 dark:text-zinc-300 hover:text-zinc-900 dark:hover:text-zinc-100 transition-colors"
              >
                Register
              </.link>
            </li>
            <li>
              <.link
                href={~p"/users/log-in"}
                class="text-zinc-600 dark:text-zinc-300 hover:text-zinc-900 dark:hover:text-zinc-100 transition-colors"
              >
                Log in
              </.link>
            </li>
          <% end %>
        </ul>
      </div>
    </header>

    <!-- AREA CENTRAL DO CONTEUDO -->
    <div class="flex-1 min-h-0 w-full overflow-hidden relative flex flex-col">
      <main class="flex-1 w-full px-4 py-4 sm:px-6 lg:px-8 flex flex-col overflow-y-auto [scrollbar-width:thin] webkit-overflow-scrolling-touch box-border pb-24 md:pb-6">
        <div class="w-full mx-auto box-border space-y-4">{render_slot(@inner_block)}</div>
      </main>
      
    <!-- BOTTOM NAV CONDICIONAL (Exibida apenas quando hide_bottom_nav for false) -->
      <%= if not @hide_bottom_nav do %>
        <.bottom_nav current_scope={@current_scope} />
      <% end %>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "flash-group", doc: "the optional id of flash container")

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/2 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=dark]_&]:left-1/2 transition-[left] duration-400" />
      <button
        class="flex p-2 cursor-pointer w-1/2"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/2"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  @doc """
  Renders the mobile bottom navigation bar.
  """
  attr(:current_scope, :map, default: nil)

  def bottom_nav(assigns) do
    ~H"""
    <footer class="md:hidden fixed bottom-0 left-0 right-0 w-full bg-white dark:bg-zinc-900 border-t border-zinc-200 dark:border-zinc-800 z-40 pb-[env(safe-area-inset-bottom,12px)]">
      <div class="flex w-full justify-around items-center h-16">
        <.link
          navigate={~p"/home"}
          class="flex flex-col items-center justify-center flex-1 text-zinc-500 dark:text-zinc-400 hover:text-orange-500 dark:hover:text-blue-500 transition-colors gap-1 active:scale-95 active:text-orange-500 dark:active:text-indigo-500"
        >
          <.icon name="hero-building-storefront" class="h-5 w-5" />
          <span class="text-[11px] font-medium leading-none">Home</span>
        </.link>

        <.link
          navigate={~p"/products"}
          class="flex flex-col items-center justify-center flex-1 text-zinc-500 dark:text-zinc-400 hover:text-orange-500 dark:hover:text-blue-500 transition-colors gap-1 active:scale-95 active:text-orange-500 dark:active:text-indigo-500"
        >
          <.icon name="hero-magnifying-glass" class="h-5 w-5" />
          <span class="text-[11px] font-medium leading-none">Search</span>
        </.link>

        <.link
          navigate={~p"/cart"}
          class="flex flex-col items-center justify-center flex-1 text-zinc-500 dark:text-zinc-400 hover:text-orange-500 dark:hover:text-blue-500 transition-colors gap-1 active:scale-95 active:text-orange-500 dark:active:text-indigo-500"
        >
          <.icon name="hero-shopping-cart" class="h-5 w-5" />
          <span class="text-[11px] font-medium leading-none">Cart</span>
        </.link>

        <.link
          navigate={~p"/orders"}
          class="flex flex-col items-center justify-center flex-1 text-zinc-500 dark:text-zinc-400 hover:text-orange-500 dark:hover:text-blue-500 transition-colors gap-1 active:scale-95 active:text-orange-500 dark:active:text-indigo-500"
        >
          <.icon name="hero-list-bullet" class="h-5 w-5" />
          <span class="text-[11px] font-medium leading-none">Orders</span>
        </.link>

        <%= if @current_scope do %>
          <.link
            navigate={~p"/users/settings"}
            class="flex flex-col items-center justify-center flex-1 text-zinc-500 dark:text-zinc-400 hover:text-orange-500 dark:hover:text-blue-500 transition-colors gap-1 active:scale-95 active:text-orange-500 dark:active:text-indigo-500"
          >
            <.icon name="hero-user" class="h-5 w-5" />
            <span class="text-[11px] font-medium leading-none">Profile</span>
          </.link>
        <% else %>
          <.link
            navigate={~p"/users/log-in"}
            class="flex flex-col items-center justify-center flex-1 text-zinc-500 dark:text-zinc-400 hover:text-orange-500 dark:hover:text-blue-500 transition-colors gap-1 active:scale-95 active:text-orange-500 dark:active:text-indigo-500"
          >
            <.icon name="hero-arrow-right-end-on-rectangle" class="h-5 w-5" />
            <span class="text-[11px] font-medium leading-none">Login</span>
          </.link>
        <% end %>
      </div>
    </footer>
    """
  end
end
