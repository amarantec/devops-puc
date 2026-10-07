defmodule KgkmWeb.ChatLive.Index do
  use KgkmWeb, :live_view

  alias Kgkm.Accounts
  alias Kgkm.Chats
  alias Kgkm.Messages
  alias Kgkm.Messages.Message

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex h-[calc(100vh-8rem)] border rounded-lg overflow-hidden">
        <!-- Sidebar Principal -->
        <aside class="w-1/3 border-r bg-gray-50 flex flex-col">
          <!-- Cabeçalho do Usuário, Botão Novo Grupo e Search Bar -->
          <div class="p-4 border-b bg-white space-y-3">
            <div class="flex justify-between items-center">
              <div class="text-sm font-semibold text-gray-600">
                <span class="text-blue-600">
                  {@current_scope.user.username}#{@current_scope.user.tag}
                </span>
              </div>
              <!-- Botão para abrir o modal de grupo -->
              <.button phx-click="open_group_modal" variant="primary" class="text-xs">
                + Novo Grupo
              </.button>
            </div>
            
    <!-- Campo de Busca de Usuários -->
            <form phx-change="search_user" phx-submit="search_user">
              <input
                type="text"
                name="query"
                value={@search_query}
                placeholder="Buscar usuário (ex: alice ou alice#2002)..."
                class="w-full text-sm rounded-lg border-gray-300 focus:ring-blue-500 focus:border-blue-500"
                autocomplete="off"
              />
            </form>
          </div>
          
    <!-- Resultados da Busca (se houver algo digitado) -->
          <%= if @search_query != "" do %>
            <div class="p-2 bg-blue-50 border-b">
              <div class="text-xs font-bold text-gray-500 mb-2 px-2 uppercase">
                Resultados da busca
              </div>
              <%= if @search_results == [] do %>
                <div class="text-xs text-gray-400 px-2 py-2">Nenhum usuário encontrado</div>
              <% else %>
                <div
                  :for={user <- @search_results}
                  class="flex items-center justify-between p-2 hover:bg-blue-100 rounded"
                >
                  <span class="text-sm font-medium">{user.username}#{user.tag}</span>
                  <.button
                    phx-click="start_dm"
                    phx-value-user-id={user.id}
                    variant="primary"
                    class="text-xs py-1 px-2"
                  >
                    Conversar
                  </.button>
                </div>
              <% end %>
            </div>
          <% end %>
          
    <!-- Lista de conversas do usuário -->
          <div class="flex-1 overflow-y-auto p-4">
            <h2 class="text-xs font-bold text-gray-500 uppercase mb-3">Minhas Conversas</h2>

            <div :for={chat <- @chats} class="mb-1">
              <.link
                patch={~p"/chats/#{chat.id}"}
                class={"block p-3 rounded-lg transition #{if @active_chat && @active_chat.id == chat.id, do: "bg-blue-100 text-blue-800 font-semibold", else: "hover:bg-gray-200"}"}
              >
                <div class="flex justify-between items-center">
                  <span>{chat.title || "Conversa Direta"}</span>
                  <span class="text-[10px] px-1.5 py-0.5 rounded bg-gray-200 text-gray-600">
                    {if chat.type == :group, do: "GRUPO", else: "DM"}
                  </span>
                </div>
              </.link>
            </div>
          </div>
        </aside>
        
    <!-- Area de Mensagens da Sala Ativa -->
        <main class="w-2/3 flex flex-col justify-between bg-gray-100">
          <%= if @active_chat do %>
            <!-- Subcabecalho da Sala -->
            <div class="p-4 border-b bg-gray-50 font-bold text-gray-700 flex justify-between items-center">
              <span>{@active_chat.title || "Chat Ativo"}</span>
            </div>
            
    <!-- Feed de Mensages (Stream) -->
            <div id="messages-feed" phx-update="stream" class="flex-1 p-4 overflow-y-auto space-y-4">
              <div
                :for={{dom_id, msg} <- @streams.messages}
                id={dom_id}
                class={"flex flex-col #{if msg.user_id == @current_scope.user.id, do: "items-end", else: "items-start"}"}
              >
                <span class="text-xs text-gray-500 mb-1">{msg.user.username || msg.user.email}</span>
                <div class={"p-3 rounded-lg max-w-md #{if msg.user_id == @current_scope.user.id, do: "bg-blue-600 text-white", else: "bg-gray-100 text-gray-800"}"}>
                  {msg.content}
                </div>
              </div>
            </div>
            
    <!-- Input de Envio de Mensagem -->
            <div class="p-4 border-t bg-gray-50">
              <.form
                for={@form}
                id="message-form"
                phx-change="validate"
                phx-submit="save"
                class="flex gap-2 items-center"
              >
                <div class="flex-1">
                  <.input
                    field={@form[:content]}
                    type="text"
                    placeholder="Digite sua mensagem..."
                    autocomplete="off"
                  />
                </div>

                <.button phx-disable-with="Enviando..." variant="primary" class="mt-2">
                  Enviar
                </.button>
              </.form>
            </div>
          <% else %>
            <div class="flex items-center justify-center h-full text-gray-400">
              Selecione um chat para começar a conversa.
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
    </Layouts.app>
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
