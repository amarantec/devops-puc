defmodule KgkmWeb.ChatLive.Index do
  alias Kgkm.Accounts
  use KgkmWeb, :live_view

  alias Kgkm.Chats
  alias Kgkm.Messages
  alias Kgkm.Messages.Message

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex h-[calc(100vh-8rem)] border rounded-lg overflow-hidden">
        <!-- Sidebar: Lista de Conversa -->
        <aside class="w-1/3 border-r bg-gray-50 flex flex-col">
          <!-- Cabeçalho do Usuário e Search Bar -->
          <div class="p-4 border-b bg-white">
            <div class="text-sm font-semibold text-gray-600 mb-2">
              Meu Perfil:
              <span class="text-blue-600">
                {@current_scope.user.username}#{@current_scope.user.tag}
              </span>
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
                {chat.title || "Conversa em Grupo / Direta"}
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
     |> assign_message_form(%Message{})}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_params(socket, socket.assigns.live_action, params)}
  end

  defp apply_params(socket, :show, %{"id" => chat_id}) do
    scope = socket.assigns.current_scope

    if connected?(socket) do
      # Cancela assinatura anterior se houver e assina novo chat
      if active_chat = socket.assigns.active_chat do
        Phoenix.PubSub.unsubscribe(Kgkm.PubSub, "chat:#{active_chat.id}:messages")
      end

      # Inscreve no topico do novo chat
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

  # --- EVENTOS DE BUSCA E INICIO DE CHAT ---
  @impl true
  def handle_event("search_user", %{"query" => query}, socket) do
    query = String.trim(query)

    results =
      if query == "" do
        []
      else
        # Se contiver "#", faz busca exata por username#tag
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
          # Se não, busca aproximada por username
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

    {:noreply,
     socket
     |> assign(form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"message" => message_params}, socket) do
    scope = socket.assigns.current_scope
    chat_id = socket.assigns.active_chat.id

    # Adiciona o chat_id garantido ao payload
    message_params = Map.put(message_params, "chat_id", chat_id)

    case Messages.create_message(scope, message_params) do
      {:ok, _message} ->
        # Limpa o formulario mantendo o chat_id ativo
        {:noreply, assign_message_form(socket, %Message{chat_id: socket.assigns.active_chat.id})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # --- PUBSUB: RECEBIMENTO EM TEMPO REAL ---

  @impl true
  def handle_info({:created, %Message{} = message}, socket) do
    # Insercao em tempo real na stream sem recarregar a pagina
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
