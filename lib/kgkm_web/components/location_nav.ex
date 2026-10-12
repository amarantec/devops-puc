defmodule KgkmWeb.LocationNav do
  use KgkmWeb, :live_component

  alias Kgkm.GeoCoding

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       city: nil,
       show_modal: false,
       search_query: "",
       search_results: [],
       loading_search: false
     )}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="location-picker"
      phx-hook="GetLocation"
      phx-target={@myself}
      class="relative flex items-center"
    >
      <!-- BOTAO PRINCIPAL / PILL DE LOCALIZACAO -->
      <button
        type="button"
        phx-click="open-modal"
        phx-target={@myself}
        class="flex items-center gap-1.5 text-xs sm:text-sm font-semibold text-zinc-700 dark:text-zinc-300 bg-zinc-100 dark:bg-zinc-800/80 hover:bg-zinc-200 dark:hover:bg-zinc-700 px-2.5 py-1.5 rounded-full transition-all border border-zinc-200/60 dark:border-zinc-700/50 cursor-pointer"
      >
        <.icon name="hero-map-pin" class="w-4 h-4 text-orange-500 dark:text-indigo-400 shrink-0" />
        <span class="truncate max-w-[110px] sm:max-w-[160px] md:max-w-none">
          {if @city, do: @city, else: "Buscando..."}
        </span>
        <.icon name="hero-chevron-down" class="w-3.5 h-3.5 opacity-60 ml-0.5" />
      </button>
      
    <!-- MODAL DE SELEÇÃO DE LOCALIZAÇÃO -->
      <%= if @show_modal do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
          <!-- Backdrop Click para Fechar -->
          <div class="fixed inset-0" phx-click="close-modal" phx-target={@myself}></div>

          <div class="relative w-full max-w-md bg-white dark:bg-zinc-900 rounded-2xl shadow-xl border border-zinc-200 dark:border-zinc-800 p-5 space-y-4 z-10">
            <!-- Header Modal -->
            <div class="flex items-center justify-between">
              <h3 class="text-base font-bold text-zinc-900 dark:text-zinc-100">
                Selecione sua localização
              </h3>
              <button
                type="button"
                phx-click="close-modal"
                phx-target={@myself}
                class="text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-200"
              >
                <.icon name="hero-x-mark" class="w-5 h-5" />
              </button>
            </div>
            
    <!-- Botão Usar Localização Atual (GPS) -->
            <button
              type="button"
              phx-click="use-gps"
              phx-target={@myself}
              class="w-full flex items-center justify-center gap-2 py-2.5 px-3 bg-orange-50 dark:bg-indigo-950/40 text-orange-600 dark:text-indigo-400 hover:bg-orange-100 dark:hover:bg-indigo-900/50 rounded-xl font-medium text-sm transition-colors border border-orange-200/60 dark:border-indigo-800/50 cursor-pointer"
            >
              <.icon name="hero-paper-airplane" class="w-4 h-4" /> Usar localização atual via GPS
            </button>
            
    <!-- Campo de Busca -->
            <form phx-change="search" phx-submit="search" phx-target={@myself} class="relative">
              <input
                type="text"
                name="query"
                value={@search_query}
                placeholder="Digite a cidade ou estado..."
                phx-debounce="400"
                autocomplete="off"
                class="w-full px-3.5 py-2.5 bg-zinc-100 dark:bg-zinc-800/80 border border-zinc-200 dark:border-zinc-700 rounded-xl text-sm text-zinc-900 dark:text-zinc-100 placeholder-zinc-400 focus:outline-hidden focus:ring-2 focus:ring-orange-500 dark:focus:ring-indigo-500"
              />
              <%= if @loading_search do %>
                <div class="absolute right-3 top-3">
                  <.icon name="hero-arrow-path" class="w-4 h-4 animate-spin text-zinc-400" />
                </div>
              <% end %>
            </form>
            
    <!-- Lista de Resultados da Busca -->
            <%= if not Enum.empty?(@search_results) do %>
              <div class="max-h-48 overflow-y-auto divide-y divide-zinc-100 dark:divide-zinc-800 rounded-xl border border-zinc-100 dark:border-zinc-800">
                <%= for result <- @search_results do %>
                  <button
                    type="button"
                    phx-click="select-city"
                    phx-value-city={result.display_name}
                    phx-target={@myself}
                    class="w-full text-left p-2.5 text-xs sm:text-sm hover:bg-zinc-100 dark:hover:bg-zinc-800/70 text-zinc-700 dark:text-zinc-300 transition-colors flex items-center gap-2"
                  >
                    <.icon name="hero-map-pin" class="w-4 h-4 text-zinc-400 shrink-0" />
                    <span class="truncate">{result.display_name}</span>
                  </button>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # --- EVENTOS DO COMPONENTE ---

  @impl true
  def handle_event("open-modal", _, socket) do
    {:noreply, assign(socket, show_modal: true)}
  end

  def handle_event("close-modal", _, socket) do
    {:noreply, assign(socket, show_modal: false, search_query: "", search_results: [])}
  end

  def handle_event("search", %{"query" => query}, socket) do
    query = String.trim(query)

    if byte_size(query) >= 3 do
      {:ok, results} = GeoCoding.search_locations(query)

      {:noreply,
       assign(socket, search_results: results, loading_search: false, search_query: query)}
    else
      {:noreply, assign(socket, search_results: [], search_query: query)}
    end
  end

  def handle_event("select-city", %{"city" => city}, socket) do
    {:noreply,
     socket
     |> assign(city: city, show_modal: false, search_query: "", search_results: [])
     |> push_event("city-resolved", %{city: city})}
  end

  def handle_event("use-gps", _, socket) do
    {:noreply,
     socket
     |> assign(show_modal: false, city: nil)
     |> push_event("request-gps", %{})}
  end

  def handle_event("location-resolved", %{"city" => city}, socket) do
    {:noreply, assign(socket, city: city)}
  end

  def handle_event("location-resolved", %{"latitude" => lat, "longitude" => lng}, socket) do
    case GeoCoding.get_city_name(lat, lng) do
      {:ok, city} ->
        {:noreply,
         socket
         |> assign(city: city)
         |> push_event("city-resolved", %{city: city})}

      {:error, _reason} ->
        {:noreply, assign(socket, city: "Localização Desconhecida")}
    end
  end

  def handle_event("location-failed", _params, socket) do
    {:noreply, assign(socket, city: "Localização Desconhecida")}
  end
end
