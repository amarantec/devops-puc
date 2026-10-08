defmodule KgkmWeb.ChatLive.Index do
  use KgkmWeb, :live_view

  alias Kgkm.Accounts
  alias Kgkm.Chats
  alias Kgkm.Messages
  alias Kgkm.Messages.Message

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-screen w-screen overflow-hidden bg-white dark:bg-grey-900">
      <%!-- Componentes de Flash Notices nativos do seu CoreComponents --%>
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
      <div class="chat-layout">
        <!-- Sidebar Principal -->
        <aside class="chat-sidebar">
          <!-- Cabeçalho do Usuário, Botão Novo Grupo e Search Bar -->
          <div class="p-3 border-b bg-gray-200 dark:border-gray-800 space-y-2 bg-white dark:bg-gray-900">
            <div class="flex justify-between items-center">
              <div class="flex items-center gap-2">
                <div class="user-avatar">
                  {String.slice(@current_scope.user.username || "U", 0, 2)}
                </div>
                <div>
                  <div class="text-sm font-semibold leading-tight">
                    {@current_scope.user.username}
                  </div>
                  <div class="text-xs text-gray-400">
                    #{@current_scope.user.tag}
                  </div>
                </div>
              </div>
              <!-- Botão para abrir o modal de grupo -->
              <.button phx-click="open_group_modal" variant="primary">
                <.icon name="hero-user-group" /> Novo Grupo
              </.button>
            </div>
            
    <!-- Campo de Busca de Usuários -->
            <form phx-change="search_user" phx-submit="search_user" class="relative">
              <input
                type="text"
                name="query"
                value={@search_query}
                placeholder="Buscar usuário (ex: alice ou alice#2002)..."
                class="w-full text-sm pl-9 pr-4 py-1.5 rounded-full border-none bg-gray-100 dark:bg-gray-800 focus:ring-2 focus:ring-orange-500 dark:focus:ring-indigo-500"
                autocomplete="off"
              />
              <.icon
                name="hero-magnifying-glass"
                class="w-4 h-4 text-gray-400 absolute left-3 top-2.5"
              />
            </form>
          </div>
          
    <!-- Resultados da Busca (se houver algo digitado) -->
          <%= if @search_query != "" do %>
            <div class="p-2 bg-orange-50/50 dark:bg-indigo-950/20 border-b border-gray-200 dark:border-gray-800">
              <div class="text-[11px] font-bold text-gray-400 mb-1 px-2 uppercase">
                Resultados
              </div>
              <%= if @search_results == [] do %>
                <div class="text-xs text-gray-400 px-2 py-1">Nenhum usuário encontrado</div>
              <% else %>
                <div
                  :for={user <- @search_results}
                  class="flex items-center justify-between p-2 hover:bg-white dark:bg-gray-800 rounded-xl transition"
                >
                  <div class="flex items-center gap-2">
                    <div class="user-avatar">{String.slice(user.username, 0, 2)}</div>
                    <span class="text-sm font-medium">{user.username}#{user.tag}</span>
                  </div>
                  <.button
                    phx-click="start_dm"
                    phx-value-user-id={user.id}
                  >
                    Conversar
                  </.button>
                </div>
              <% end %>
            </div>
          <% end %>
          
    <!-- Lista de conversas do usuário -->
          <div class="flex-1 overflow-y-auto p-2 space-y-1">
            <div :for={chat <- @chats}>
              <.link
                patch={~p"/chats/#{chat.id}"}
                class={"flex items-center gap-3 p-2.5 rounded-2xl transition #{if @active_chat && @active_chat.id == chat.id, do: "bg-orange-500 text-white dark:bg-indigo-600", else: "hover:bg-gray-100 dark:hover:bg-gray-800"}"}
              >
                <div class={"user-avatar #{if @active_chat && @active_chat.id == chat.id, do: "!bg-white/20 !text-white"}"}>
                  {if chat.type == :group, do: "G", else: "D"}
                </div>
                <div class="flex-1 min-w-0">
                  <div class="flex justify-between items-baseline">
                    <p class="text-sm font-semibold truncate">{chat.title || "Conversa Direta"}</p>
                    <span class="text-[10px] opacity-75">
                      {if chat.type == :group, do: "Grupo", else: "DM"}
                    </span>
                  </div>
                </div>
              </.link>
            </div>
          </div>
          
    <!-- Botão Flutuante (FAB) Estilo Telegram no canto da Sidebar -->
          <div class="absolute bottom-4 right-4">
            <.button phx-click="open_group_modal" variant="primary">
              <.icon name="hero-pencil" />
            </.button>
          </div>
        </aside>
        
    <!-- Area de Mensagens da Sala Ativa -->
        <main class="flex-1 flex flex-col justify-between bg-gray-100/60 dark:bg-gray-950 relative">
          <%= if @active_chat do %>
            <!-- Subcabeçalho da Conversa -->
            <div class="p-3 border-b bg-gray-200 dark:border-gray-800 bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm flex items-center gap-3 z-10">
              <div class="user-avatar">
                {if @active_chat.type == :group, do: "G", else: "D"}
              </div>
              <div>
                <h3 class="text-sm font-bold leading-tight">{@active_chat.title || "DM"}</h3>
                <p class="text-xs text-gray-400">em tempo real</p>
              </div>
            </div>
            
    <!-- Feed de Mensages (Stream) -->
            <div
              id="messages-feed"
              phx-update="stream"
              class="flex-1 p-4 overflow-y-auto flex flex-col space-y-2"
            >
              <div class="chat-date-badge">Hoje</div>
              <div
                :for={{dom_id, msg} <- @streams.messages}
                id={dom_id}
                class={"flex flex-col #{if msg.user_id == @current_scope.user.id, do: "items-end", else: "items-start"}"}
              >
                <%= if msg.user_id != @current_scope.user.id do %>
                  <span class="text-[10px] text-gray-400 ml-2 mb-0.5">{msg.user.username}</span>
                <% end %>
                <div class={
                  if msg.user_id == @current_scope.user.id,
                    do: "msg-bubble-sent",
                    else: "msg-bubble-received"
                }>
                  <p class="break-word">{msg.content}</p>
                  <div class="text-[9px] text-right mt-1 opacity-75">
                    {Calendar.strftime(msg.inserted_at, "%H:%M")}
                  </div>
                </div>
              </div>
            </div>
            
    <!-- Input de Envio de Mensagem sem bordas estranhas -->
            <div class="p-3 bg-white dark:bg-gray-900 border-t border-gray-200 dark:border-gray-800">
              <.form
                for={@form}
                id="message-form"
                phx-change="validate"
                phx-submit="save"
                class="flex items-center gap-2"
              >
                <div class="flex-1">
                  <input
                    type="text"
                    name={@form[:content].name}
                    value={@form[:content].value}
                    placeholder="Escreva uma mensagem..."
                    autocomplete="off"
                    class="w-full text-sm px-4 py-2.5 rounded-full border-none bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>

                <.button phx-disable-with="..." variant="primary" class="!rounded-full !p-3 shrink-0">
                  <.icon name="hero-paper-airplane" class="w-4 h-4" />
                </.button>
              </.form>
            </div>
          <% else %>
            <div class="flex flex-col items-center justify-center h-full text-gray-400 space-y-2">
              <.icon name="hero-chat-bubble-left-right" class="w-12 h-12 stroke-1" />
              <p class="text-sm">Selecione um chat para começar a conversa.</p>
            </div>
          <% end %>
        </main>
      </div>
      
    <!-- MODAL FUNCIONAL DE CRIAÇÃO DE GRUPO -->
      <%= if @show_group_modal? do %>
        <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div class="bg-white p-6 rounded-lg w-full max-w-md space-y-4">
            <div class="flex justify-between items-center border-b pb-2">
              <h3 class="text-lg font-bold">Criar Novo Grupo</h3>
              <button phx-click="close_group_modal" class="text-gray-500 font-bold">✕</button>
            </div>

            <.form for={%{}} phx-submit="create_group" class="space-y-4">
              <div>
                <label class="block text-sm font-medium mb-1">Nome do Grupo</label>
                <input
                  type="text"
                  name="group_title"
                  placeholder="ex: Projeto Elixir"
                  required
                  class="w-full text-sm rounded border-gray-300"
                />
              </div>
              
    <!-- Busca e Seleção de Membros -->
              <div>
                <label class="block text-sm font-medium mb-1">Buscar Membro por Tag/Username</label>
                <input
                  type="text"
                  phx-keyup="search_group_member"
                  name="member_query"
                  placeholder="ex: alice#2002"
                  class="w-full text-sm rounded border-gray-300 mb-2"
                  autocomplete="off"
                />
                
    <!-- Resultados de Busca de Membros -->
                <%= if @group_search_results != [] do %>
                  <div class="border rounded p-2 bg-gray-50 max-h-32 overflow-y-auto mb-2 space-y-1">
                    <div
                      :for={user <- @group_search_results}
                      class="flex justify-between items-center text-xs"
                    >
                      <span>{user.username}#{user.tag}</span>
                      <.button
                        type="button"
                        phx-click="add_member_to_group"
                        phx-value-user-id={user.id}
                        phx-value-username={user.username}
                        class="text-[10px] py-0.5 px-2"
                      >
                        <.icon name="hero-plus" /> Adicionar
                      </.button>
                    </div>
                  </div>
                <% end %>
                
    <!-- Membros Selecionados -->
                <div class="text-xs font-semibold text-gray-500 mb-1">Membros Selecionados:</div>
                <div class="flex flex-wrap gap-1 border p-2 rounded min-h-[40px]">
                  <span class="bg-blue-100 text-blue-800 text-xs px-2 py-0.5 rounded">
                    Você (criador)
                  </span>
                  <span
                    :for={member <- @selected_group_members}
                    class="bg-gray-200 text-gray-800 text-xs px-2 py-0.5 rounded flex items-center gap-1"
                  >
                    {member.username}
                    <button
                      type="button"
                      phx-click="remove_member_from_group"
                      phx-value-user-id={member.id}
                      class="text-red-500 font-bold"
                    >
                      ✕
                    </button>
                  </span>
                </div>
              </div>

              <div class="flex justify-end gap-2 pt-2 border-t">
                <.button type="button" phx-click="close_group_modal" class="bg-gray-300 text-black">
                  Cancelar
                </.button>
                <.button type="submit" variant="primary">
                  Criar Grupo
                </.button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    {:ok,
     socket
     |> assign(:chats, Chats.list_user_chats(scope))
     |> assign(:active_chat, nil)
     |> assign(:search_query, "")
     |> assign(:search_results, [])
     # Estados para o Modal de Grupo
     |> assign(:show_group_modal?, false)
     |> assign(:group_search_results, [])
     |> assign(:selected_group_members, [])
     |> assign_message_form(%Message{})}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_params(socket, socket.assigns.live_action, params)}
  end

  defp apply_params(socket, :show, %{"id" => chat_id}) do
    scope = socket.assigns.current_scope

    if connected?(socket) do
      if active_chat = socket.assigns.active_chat do
        Phoenix.PubSub.unsubscribe(Kgkm.PubSub, "chat:#{active_chat.id}:messages")
      end

      Messages.subscribe_chat_messages(chat_id)
    end

    chat = Chats.get_chat!(scope, chat_id)
    messages = Messages.list_messages(chat_id)

    socket
    |> assign(:active_chat, chat)
    |> assign_message_form(%Message{chat_id: chat.id})
    |> stream(:messages, messages, reset: true)
  end

  defp apply_params(socket, :index, _params) do
    socket
    |> assign(:active_chat, nil)
    |> stream(:messages, [], reset: true)
  end

  # --- HANDLERS DO MODAL DE GRUPO ---

  @impl true
  def handle_event("open_group_modal", _params, socket) do
    {:noreply,
     assign(socket, show_group_modal?: true, group_search_results: [], selected_group_members: [])}
  end

  @impl true
  def handle_event("close_group_modal", _params, socket) do
    {:noreply, assign(socket, show_group_modal?: false)}
  end

  @impl true
  def handle_event("search_group_member", %{"value" => query}, socket) do
    query = String.trim(query)

    results =
      if query == "" do
        []
      else
        if String.contains?(query, "#") do
          case String.split(query, "#") do
            [username, tag] ->
              case Accounts.get_user_by_username_and_tag(username, tag) do
                nil -> []
                user -> [user]
              end

            _ ->
              []
          end
        else
          Accounts.search_users_by_username(query, socket.assigns.current_scope.user.id)
        end
      end

    {:noreply, assign(socket, group_search_results: results)}
  end

  @impl true
  def handle_event("add_member_to_group", %{"user-id" => user_id, "username" => username}, socket) do
    selected = socket.assigns.selected_group_members

    updated_members =
      if Enum.any?(selected, fn m -> m.id == user_id end) do
        selected
      else
        [%{id: user_id, username: username} | selected]
      end

    {:noreply, assign(socket, selected_group_members: updated_members, group_search_results: [])}
  end

  @impl true
  def handle_event("remove_member_from_group", %{"user-id" => user_id}, socket) do
    updated_members =
      Enum.reject(socket.assigns.selected_group_members, fn m -> m.id == user_id end)

    {:noreply, assign(socket, selected_group_members: updated_members)}
  end

  @impl true
  def handle_event("create_group", %{"group_title" => title}, socket) do
    scope = socket.assigns.current_scope
    member_ids = Enum.map(socket.assigns.selected_group_members, & &1.id)

    case Chats.create_group_chat(scope, title, member_ids) do
      {:ok, chat} ->
        {:noreply,
         socket
         |> assign(show_group_modal?: false, selected_group_members: [])
         |> assign(:chats, Chats.list_user_chats(scope))
         |> push_patch(to: ~p"/chats/#{chat.id}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erro ao criar grupo.")}
    end
  end

  # --- EVENTOS DE BUSCA E INICIO DE CHAT (DM) ---

  @impl true
  def handle_event("search_user", %{"query" => query}, socket) do
    query = String.trim(query)

    results =
      if query == "" do
        []
      else
        if String.contains?(query, "#") do
          case String.split(query, "#") do
            [username, tag] ->
              case Accounts.get_user_by_username_and_tag(username, tag) do
                nil -> []
                user -> [user]
              end

            _ ->
              []
          end
        else
          Accounts.search_users_by_username(query, socket.assigns.current_scope.user.id)
        end
      end

    {:noreply, assign(socket, search_query: query, search_results: results)}
  end

  @impl true
  def handle_event("start_dm", %{"user-id" => target_user_id}, socket) do
    scope = socket.assigns.current_scope

    case Chats.find_or_create_direct_chat(scope, target_user_id) do
      {:ok, chat} ->
        {:noreply,
         socket
         |> assign(search_query: "", search_results: [])
         |> assign(:chats, Chats.list_user_chats(scope))
         |> push_patch(to: ~p"/chats/#{chat.id}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Não foi possível iniciar a conversa")}
    end
  end

  # --- EVENTOS DE MENSAGEM ---

  @impl true
  def handle_event("validate", %{"message" => message_params}, socket) do
    scope = socket.assigns.current_scope

    changeset =
      Messages.change_message(
        scope,
        %Message{},
        message_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"message" => message_params}, socket) do
    scope = socket.assigns.current_scope
    chat_id = socket.assigns.active_chat.id

    message_params = Map.put(message_params, "chat_id", chat_id)

    case Messages.create_message(scope, message_params) do
      {:ok, _message} ->
        {:noreply, assign_message_form(socket, %Message{chat_id: socket.assigns.active_chat.id})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # --- PUBSUB: RECEBIMENTO EM TEMPO REAL ---

  @impl true
  def handle_info({:created, %Message{} = message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info(_other, socket), do: {:noreply, socket}

  # Funcoes auxiliares
  defp assign_message_form(socket, %Message{} = message) do
    scope = socket.assigns.current_scope
    changeset = Messages.change_message(scope, message)
    assign(socket, :form, to_form(changeset))
  end
end
