defmodule KgkmWeb.ChatLive.Index do
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
        <aside class="w-1/3 border-r bg-gray-50 p-4 oevrflow-y-auto">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-lg font-bold">Conversas</h2>
          </div>
          <div :for={chat <- @chats} class="mb-1">
            <.link
              patch={~p"/chats/#{chat.id}"}
              class={"block p-3 rounded-lg transition #{if @active_chat && @active_chat.id == chat.id, do: "bg-blue-100 text-blue-800 font-semibold", else: "hover:bg-gray-200"}"}
            >
              {chat.title || "Conversa em Grupo / Direta"}
            </.link>
          </div>
        </aside>
        
    <!-- Area de Mensagens e Formulario -->
        <main class="w-2/3 flex flex-col justify-between bg-white">
          <%= if @active_chat do %>
            <!-- Subcabecalho da Sala -->
            <div class="p-4 border-b bg-gray-50 font-bold text-gray-700">
              {@active_chat.title || "Chat Ativo"}
            </div>
            
    <!-- Feed de Mensages (Stream) -->
            <div id="messages-feed" phx-update="stream" class="flex-1 p-4 overflow-y-auto space-y-4">
              <div
                :for={{dom_id, msg} <- @streams.messages}
                id={dom_id}
                class={"flex flex-col #{if msg.user_id == @current_scope.user.id, do: "items-end", else: "items-start"}"}
              >
                <span class="text-xs text-gray-500 mb-1">{msg.user.email}</span>
                <div class={"p-3 rounded-lg max-w-md #{if msg.user_id == @current_scope.user.id, do: "bg-blue-600 text-white", else: "bg-gray-100 text-gray-800"}"}>
                  {msg.content}
                </div>
              </div>
            </div>
            
    <!-- Formulario de Envio de Mensagem -->
            <div class="p-4 border-t bg-gray-50">
              <.form
                for={@form}
                id="message-form"
                phx-change="validate"
                phx-submit="save"
                class="flex gap-2 items-center"
              >
                <%!-- Input Hidden para garantir que o chat_id é enviado no payload --%>
                <div class="flex-1">
                  <.input
                    field={@form[:content]}
                    type="text"
                    placeholder="Digitee sua mensagem..."
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
     |> assign(:chats, Chats.list_chats(scope))
     |> assign(:active_chat, nil)
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

  # --- EVENTOS DO FORMULÁRIO DE MENSAGEM ---
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
