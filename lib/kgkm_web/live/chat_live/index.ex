defmodule KgkmWeb.ChatLive.Index do
  use KgkmWeb, :live_view

  alias Kgkm.Accounts
  alias Kgkm.Chats
  alias Kgkm.Messages
  alias Kgkm.Messages.Message
  import KgkmWeb.CoreComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} hide_bottom_nav={true}>
      <div
        id="chat-app-root"
        phx-hook="PageTitle"
        class="chat-container-layout"
      >
        <div class="chat-layout w-full h-full flex overflow-hidden relative">
          <!-- Sidebar: Visível no mobile APENAS SE não houver chat ativo, no DESKTOP fica sempre visível (md:flex) -->
          <aside class={"chat-sidebar-responsive #{if @active_chat, do: "hidden md:flex", else: "flex"}"}>
            <!-- Cabeçalho do Usuário, Botão Novo Grupo e Search Bar -->
            <div class="chat-header shrink-0">
              <.dropdown id="main-menu">
                <:trigger>
                  <button class="chat-menu-btn cursor-pointer p-2 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300">
                    <.icon name="hero-chat-bubble-left-right" class="w-6 h-6" />
                  </button>
                </:trigger>

                <:item phx-click="open_group_modal">
                  <.icon name="hero-user-group" class="w-5 h-5 text-orange-500 dark:text-indigo-500" />
                  <span>Novo Grupo</span>
                </:item>

                <:item phx-click="open_saved_messages">
                  <.icon name="hero-bookmark" class="w-5 h-5 text-pink-500" />
                  <span>Conversas Salvas</span>
                </:item>

                <:item navigate={~p"/users/settings"}>
                  <.icon name="hero-user" class="w-5 h-5 text-green-500" />
                  <span>Contatos</span>
                </:item>

                <:item navigate={~p"/users/settings"}>
                  <.icon name="hero-cog-6-tooth" class="w-5 h-5 text-gray-500" />
                  <span>Configurações</span>
                </:item>
                <:item href={~p"/users/log-out"} method="delete" class="text-error">
                  <.icon name="hero-arrow-right-on-rectangle" class="w-5 h-5" />
                  <span>Log out</span>
                </:item>
              </.dropdown>

    <!-- Campo de Busca de Usuários -->
              <form phx-change="search_user" phx-submit="search_user" class="relative flex-1">
                <input
                  type="text"
                  name="query"
                  value={@search_query}
                  placeholder="Buscar usuário..."
                  class="search-user-input w-full text-sm pl-9 pr-4 py-1.5 rounded-full border-none bg-gray-100 dark:bg-gray-800 focus:ring-2 focus:ring-orange-500 dark:focus:ring-indigo-500"
                  autocomplete="off"
                />
                <.icon
                  name="hero-magnifying-glass"
                  class="w-4 h-4 text-gray-400 absolute left-3 top-2.5"
                />
              </form>
            </div>

    <!-- Resultados da Busca -->
            <%= if @search_query != "" do %>
              <div class="p-2 bg-orange-50/50 dark:bg-indigo-950/20 border-b border-gray-200 dark:border-gray-800 shrink-0">
                <div class="text-[11px] font-bold text-gray-400 mb-1 px-2 uppercase">
                  Contatos
                </div>
                <%= if @search_results == [] do %>
                  <div class="text-xs text-gray-400 px-2 py-1">Nenhum usuário encontrado</div>
                <% else %>
                  <div
                    :for={user <- @search_results}
                    class="flex items-center justify-between p-2 hover:bg-white dark:hover:bg-gray-800 rounded-xl transition"
                  >
                    <div class="flex items-center gap-2 min-w-0">
                      <div class="user-avatar">{String.slice(user.username, 0, 2)}</div>
                      <span class="text-sm font-medium truncate">{user.username}#{user.tag}</span>
                    </div>
                    <.button
                      phx-click="start_dm"
                      phx-value-user-id={user.id}
                      class="cursor-pointer"
                    >
                      Conversar
                    </.button>
                  </div>
                <% end %>
              </div>
            <% end %>

    <!-- Lista de conversas do usuário -->
            <div class="flex-1 overflow-y-auto p-2 space-y-1">
              <div :for={chat <- @chats} class="relative group">
                <% info = chat_display_info(chat, @current_scope.user.id) %>

                <div class={"flex items-center gap-3 p-2.5 rounded-2xl transition #{if @active_chat && @active_chat.id == chat.id, do: "bg-orange-500 text-white dark:bg-indigo-500", else: "hover:bg-gray-100 dark:hover:bg-gray-800"}"}>

    <!-- Link que seleciona o chat -->
                  <.link patch={~p"/chats/#{chat.id}"} class="flex items-center gap-3 flex-1 min-w-0">
                    <div class={"user-avatar overflow-hidden #{if @active_chat && @active_chat.id == chat.id, do: "!bg-white/20 !text-white"}"}>
                      <%= if info.avatar_url do %>
                        <img src={info.avatar_url} class="w-full h-full object-cover" alt="Avatar" />
                      <% else %>
                        {info.initials}
                      <% end %>
                    </div>

                    <div class="flex-1 min-w-0">
                      <div class="flex justify-between items-baseline">
                        <p class="text-sm font-semibold truncate">{info.title}</p>
                        <span class="text-[10px] opacity-75">
                          {if chat.type == :group, do: "Grupo", else: "DM"}
                        </span>
                      </div>
                    </div>
                  </.link>

    <!-- BADGE DE NÃO LIDAS -->
                  <%= if chat.unread_count > 0 do %>
                    <span class="bg-orange-500 dark:bg-indigo-500 text-white text-[11px] font-bold px-2 py-0.5 rounded-full shrink-0">
                      {chat.unread_count}
                    </span>
                  <% end %>

    <!-- COMPONENTE DO DROPDOWN INDIVIDUAL -->
                  <% member = Enum.find(chat.chat_members, &(&1.user_id == @current_scope.user.id)) %>
                  <% is_muted? = if member, do: member.is_muted?, else: false %>

                  <.chat_actions_dropdown chat_id={chat.id} is_muted?={is_muted?} />
                </div>
              </div>
            </div>
          </aside>

    <!-- Area de Mensagens da Sala Ativa -->
          <main class={"chat-main-responsive #{if @active_chat, do: "flex", else: "hidden md:flex"}"}>
            <%= if @active_chat do %>
              <% active_info = chat_display_info(@active_chat, @current_scope.user.id) %>

    <!-- Subcabeçalho da Conversa -->
              <div class="chat-subheader p-3 border-b border-gray-200 dark:border-gray-800 bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm flex items-center gap-3 z-10 shrink-0">
                <.link
                  patch={~p"/chats"}
                  class="md:hidden p-1.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300"
                >
                  <.icon name="hero-arrow-left" class="w-5 h-5 text-orange-500 dark:text-indigo-500" />
                </.link>

                <div class="user-avatar overflow-hidden">
                  <%= if active_info.avatar_url do %>
                    <img src={active_info.avatar_url} class="w-full h-full object-cover" alt="Avatar" />
                  <% else %>
                    {active_info.initials}
                  <% end %>
                </div>
                <div>
                  <h3 class="text-sm font-bold leading-tight">{active_info.title}</h3>
                  <p class="text-xs text-orange-500 dark:text-indigo-500 font-medium animate-pulse">
                    <%= if @typing_user do %>
                      {@typing_user} está digitando...
                    <% else %>
                      em tempo real
                    <% end %>
                  </p>
                </div>
              </div>

    <!-- Feed de Mensagens (Stream com Scroll Independente e Botão FAB de Scroll) -->
              <div class="relative flex-1 min-h-0 flex flex-col">
                <div
                  :if={@active_chat}
                  id={"messages-feed-#{@active_chat.id}"}
                  phx-hook="ChatScroll"
                  phx-update="stream"
                  class="flex-1 p-4 sm:p-6 overflow-y-auto flex flex-col space-y-2"
                >
                  <div class="chat-date-badge" id="date-badge">Hoje</div>
                  <div
                    :for={{dom_id, msg} <- @streams.messages}
                    id={"message-#{msg.id}"}
                    class={"flex flex-col group relative #{if msg.user_id == @current_scope.user.id, do: "items-end", else: "items-start"}"}
                  >
                    <%= if msg.user_id != @current_scope.user.id do %>
                      <span class="text-[10px] text-gray-400 ml-2 mb-0.5">{msg.user.username}</span>
                    <% end %>

                    <div class="flex items-center gap-1.5 max-w-[85%] md:max-w-md">
                      <%= if msg.user_id == @current_scope.user.id do %>
                        <.msg_actions_dropdown msg_id={msg.id} msg_content={msg.content} is_me={true} />
                      <% end %>

                      <div class={
                        if msg.user_id == @current_scope.user.id,
                          do: "msg-bubble-sent",
                          else: "msg-bubble-received"
                      }>
                        <%= if Map.get(msg, :reply_to) && msg.reply_to do %>
                          <div
                            class="reply-message"
                            onclick={"window.dispatchEvent(new CustomEvent('scroll_to_message', { detail: { msgId: '#{msg.reply_to.id}' } }))"}
                          >
                            <p class="font-bold opacity-90">{msg.reply_to.user.username}</p>
                            <p class="truncate opacity-75">{msg.reply_to.content}</p>
                          </div>
                        <% end %>

                        <%= if msg.file_url do %>
                          <% ext = String.downcase(Path.extname(msg.file_url)) %>
                          <%= if ext in [".jpg", ".jpeg", ".png", ".webp", ".gif"] do %>
                            <div class="mb-2 rounded-2xl overflow-hidden max-w-xs cursor-pointer group/img relative">
                              <img
                                src={msg.file_url}
                                class="w-full h-auto object-cover rounded-2xl transition group-hover/img:scale-105"
                                alt="Foto"
                                onclick={"window.open('#{msg.file_url}', '_blank')"}
                              />
                            </div>
                          <% else %>
                            <%= if ext in [".mp3", ".wav", ".ogg"] do %>
                              <div class="mb-2 min-w-[200px]">
                                <audio controls class="w-full h-10">
                                  <source src={msg.file_url} />
                                </audio>
                              </div>
                            <% else %>
                              <div class="mb-2 p-3 rounded-2xl bg-black/5 dark:bg-white/5 flex items-center justify-between gap-3 min-w-[200px]">
                                <p class="text-xs font-bold truncate">
                                  {Path.basename(msg.file_url)}
                                </p>
                                <a
                                  href={msg.file_url}
                                  download
                                  class="p-1.5 hover:bg-black/10 rounded-lg"
                                >
                                  <.icon name="hero-arrow-down-tray" class="w-4 h-4" />
                                </a>
                              </div>
                            <% end %>
                          <% end %>
                        <% end %>
                        <p class="break-words">{msg.content}</p>
                        <div class="text-[9px] text-right mt-1 opacity-75 flex items-center justify-end gap-1">
                          <span>{Calendar.strftime(msg.inserted_at, "%H:%M")}</span>
                          <%= if msg.user_id == @current_scope.user.id do %>
                            <%= case msg.status do %>
                              <% :read -> %>
                                <!-- Check duplo azul (Lido) -->
                                <span class="text-sky-400 font-bold" title="Lido">✓✓</span>
                              <% :delivered -> %>
                                <!-- Check duplo cinza (Entregue) -->
                                <span class="opacity-75" title="Entregue">✓✓</span>
                              <% :sent -> %>
                                <!-- Check único cinza (Enviado) -->
                                <span class="opacity-75" title="Enviado">✓</span>
                              <% _ -> %>
                                <span class="opacity-75" title="Enviado">✓</span>
                            <% end %>
                          <% end %>
                        </div>
                      </div>

                      <%= if msg.user_id != @current_scope.user.id do %>
                        <.msg_actions_dropdown
                          msg_id={msg.id}
                          msg_content={msg.content}
                          is_me={false}
                        />
                      <% end %>
                    </div>
                  </div>
                </div>

    <!-- Botão flutuante para descer ao fim do chat (Scroll FAB) -->
                <div class="sticky bottom-4 self-end mr-2 z-20 mt-auto">
                  <button
                    type="button"
                    id="scroll-to-bottom-btn"
                    class="scroll-fab-btn"
                    title="Ir para mensagens recentes"
                  >
                    <.icon
                      name="hero-arrow-down"
                      class="w-5 h-5 text-orange-500 dark:text-indigo-500"
                    />
                  </button>
                </div>
              </div>

    <!-- Rodapé fixo: Caixas de citação, previews e inputs -->
              <div class="shrink-0 bg-white dark:bg-gray-900 border-t border-gray-200 dark:border-gray-800">
                <%= if @replying_to do %>
                  <div class="px-4 py-2 bg-gray-100 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between">
                    <div class="text-xs truncate">
                      <p class="font-bold text-orange-500 dark:text-indigo-500">
                        Respondendo a {@replying_to.user.username}
                      </p>
                      <p class="text-gray-500 dark:text-gray-400 truncate">{@replying_to.content}</p>
                    </div>
                    <button
                      phx-click="cancel_reply"
                      class="text-gray-400 hover:text-gray-600 font-bold"
                    >
                      x
                    </button>
                  </div>
                <% end %>

                <%= for entry <- @uploads.chat_file.entries do %>
                  <div class="px-4 py-2 bg-gray-50 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between text-xs">
                    <span class="font-medium truncate">{entry.client_name}</span>
                    <button
                      type="button"
                      phx-click="cancel-upload"
                      phx-value-ref={entry.ref}
                      class="text-red-500"
                    >
                      <.icon name="hero-x-mark" class="w-5 h-5" />
                    </button>
                  </div>
                <% end %>

                <.form
                  for={@form}
                  id="message-form"
                  phx-change="validate"
                  phx-submit="save"
                  class="p-3 flex items-center gap-2"
                >
                  <label class="p-2.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 cursor-pointer shrink-0 flex items-center justify-center">
                    <.icon
                      name="hero-paper-clip"
                      class="w-5 h-5 text-orange-500 dark:text-indigo-500"
                    />
                    <.live_file_input upload={@uploads.chat_file} class="sr-only" />
                  </label>
                  <button
                    type="button"
                    phx-click="open_camera_modal"
                    class="p-2.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 shrink-0 flex items-center justify-center cursor-pointer"
                  >
                    <.icon name="hero-camera" class="w-5 h-5 text-orange-500 dark:text-indigo-500" />
                  </button>
                  <div class="flex-1 flex items-center">
                    <input
                      type="text"
                      name={@form[:content].name}
                      value={@form[:content].value}
                      placeholder="Escreva uma mensagem..."
                      autocomplete="off"
                      class="chat-input-message !m-0"
                    />
                  </div>
                  <%= if (is_nil(@form[:content].value) || @form[:content].value == "") && @uploads.chat_file.entries == [] do %>
                    <button
                      type="button"
                      id="audio-mic-button"
                      phx-hook="MediaRecorder"
                      class="audio-mic-button cursor-pointer"
                      title="Gravar Áudio"
                    >
                      <.icon
                        name="hero-microphone"
                        class="w-5 h-5 text-orange-500 dark:text-indigo-500"
                      />
                    </button>
                  <% else %>
                    <.button
                      variant="primary"
                      type="submit"
                      phx-disable-with="..."
                      title="Enviar Mensagem"
                    >
                      <.icon name="hero-paper-airplane" class="w-4 h-4 text-white" />
                    </.button>
                  <% end %>
                </.form>
              </div>
            <% else %>
              <div class="flex flex-col items-center justify-center h-full text-gray-400 space-y-2">
                <.icon name="hero-chat-bubble-left-right" class="w-12 h-12 stroke-1 opacity-50" />
                <p class="text-sm">Selecione um chat para começar a conversa.</p>
              </div>
            <% end %>
          </main>
        </div>
      </div>

    <!-- MODAIS DO SISTEMA DE CHAT -->
      <KgkmWeb.CoreComponents.group_modal
        show={@show_group_modal?}
        group_search_results={@group_search_results}
        selected_group_members={@selected_group_members}
      />
      <%= if @show_camera_modal? do %>
        <KgkmWeb.CoreComponents.camera_modal show={@show_camera_modal?} />
      <% end %>

      <KgkmWeb.CoreComponents.saved_messages_modal
        show={@show_saved_modal?}
        saved_messages={@saved_messages}
      />
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope
    chats = load_user_chats(scope)

    if connected?(socket) do
      # Inscreve o usuário em TODOS os chats dele para escutar mensagens em background
      Enum.each(chats, fn chat ->
        Messages.subscribe_chat_messages(chat.id)
      end)
    end

    {:ok,
     socket
     |> assign(:chats, chats)
     |> assign(:active_chat, nil)
     |> assign(:search_query, "")
     |> assign(:search_results, [])
     # Estados para o Modal de Grupo
     |> assign(:show_group_modal?, false)
     |> assign(:group_search_results, [])
     |> assign(:selected_group_members, [])
     |> assign(:replying_to, nil)
     |> assign(:typing_user, nil)
     |> allow_upload(:chat_file,
       accept: ~w(.jpg .jpeg .png .pdf .doc  .docx .mp3 .wav .mp4),
       max_entries: 1,
       # Ex: até 50mb
       max_file_size: 50_000_000
     )
     |> assign(:show_camera_modal?, false)
     |> assign(:show_saved_modal?, false)
     |> assign(:saved_messages, [])
     |> assign_message_form(%Message{})}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_params(socket, socket.assigns.live_action, params)}
  end

  defp apply_params(socket, :show, %{"id" => chat_id}) do
    scope = socket.assigns.current_scope

    # Gerenciamento limpo de PubSub do chat anterior para o novo
    if connected?(socket) do
      if active_chat = socket.assigns.active_chat do
        Phoenix.PubSub.unsubscribe(Kgkm.PubSub, "chat:#{active_chat.id}:messages")
        Phoenix.PubSub.unsubscribe(Kgkm.PubSub, "chat:#{active_chat.id}:typing")
        Phoenix.PubSub.subscribe(Kgkm.PubSub, "chat:#{active_chat.id}:read")
      end

      Messages.subscribe_chat_messages(chat_id)
      Phoenix.PubSub.subscribe(Kgkm.PubSub, "chat:#{chat_id}:typing")
    end

    chat = Chats.get_chat!(scope, chat_id)
    messages = Messages.list_messages(chat_id, scope.user.id)

    # Marca as mensagens como lidas para este chat
    Messages.mark_chat_messages_as_read(chat_id, scope.user.id)

    # Zera as mensagens não lidas apenas do chat aberto preservando os outros contadores
    updated_chats =
      Enum.map(socket.assigns.chats, fn c ->
        c = Map.put_new(c, :unread_count, 0)
        if c.id == chat_id, do: %{c | unread_count: 0}, else: c
      end)

    socket
    |> assign(:chats, updated_chats)
    |> notify_total_unread()
    |> assign(:active_chat, chat)
    # Reseta o estado de digitação ao trocar de chat
    |> assign(:typing_user, nil)
    |> assign_message_form(%Message{chat_id: chat.id})
    |> stream(:messages, [], reset: true)
    |> stream(:messages, messages)
  end

  defp apply_params(socket, :index, _params) do
    if connected?(socket) do
      if active_chat = socket.assigns.active_chat do
        Phoenix.PubSub.unsubscribe(Kgkm.PubSub, "chat:#{active_chat.id}:messages")
      end
    end

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

    # Dispara o evento de digitação via PubSub
    if chat = socket.assigns.active_chat do
      Phoenix.PubSub.broadcast(
        Kgkm.PubSub,
        "chat:#{chat.id}:typing",
        {:typing, scope.user.username}
      )
    end

    changeset =
      Messages.change_message(
        scope,
        %Message{},
        message_params
      )
      # Mantém os parâmetros ativos no form para o input não limpar o texto
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"message" => message_params}, socket) do
    scope = socket.assigns.current_scope
    chat_id = socket.assigns.active_chat.id
    replying_to = socket.assigns.replying_to

    # consome o arquivo carregado (se houver)
    file_url =
      consume_uploaded_entries(socket, :chat_file, fn %{path: path}, entry ->
        dest_dir = Path.join([:code.priv_dir(:kgkm), "static", "uploads"])
        File.mkdir_p!(dest_dir)

        ext = Path.extname(entry.client_name)
        filename = "chat-file-#{System.unique_integer([:positive])}#{ext}"
        dest_path = Path.join(dest_dir, filename)

        File.cp!(path, dest_path)
        {:ok, "/uploads/#{filename}"}
      end)
      |> List.first()

    # Monta os parâmetros finais juntando chat_id, file_url e reply_to_id
    final_params =
      message_params
      |> Map.put("chat_id", chat_id)
      |> then(fn params ->
        if file_url, do: Map.put(params, "file_url", file_url), else: params
      end)
      |> then(fn params ->
        if replying_to, do: Map.put(params, "reply_to_id", replying_to.id), else: params
      end)

    case Messages.create_message(scope, final_params) do
      {:ok, _message} ->
        {:noreply,
         socket
         # Limpa a caixa de resposta acoplada
         |> assign(:replying_to, nil)
         |> assign_message_form(%Message{chat_id: chat_id})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :insert))}
    end
  end

  # --- PUBSUB: RECEBIMENTO EM TEMPO REAL ---

  @impl true
  def handle_info({:created, %Message{} = message}, socket) do
    active_chat = socket.assigns.active_chat
    current_user = socket.assigns.current_scope.user

    if active_chat && active_chat.id == message.chat_id do
      # Se o usuário está no chat atual, apenas insere na stream
      {:noreply, stream_insert(socket, :messages, message)}
    else
      # Se a mensagem veio de OUTRO chat:
      # Incrementa o contador de não lidas do chat correspondente na sidebar
      updated_chats =
        Enum.map(socket.assigns.chats, fn chat ->
          if chat.id == message.chat_id do
            Map.update(chat, :unread_count, 1, &(&1 + 1))
          else
            chat
          end
        end)

      # Dispara uma notificação flash se a mensagem não foi enviada pelo próprio usuário
      socket =
        if message.user_id != current_user.id do
          sender_name = message.user.username || "Someone"
          put_flash(socket, :info, "Nova mensagem de #{sender_name}")
        else
          socket
        end

      {:noreply,
       socket
       |> assign(chats: updated_chats)
       |> notify_total_unread()}
    end
  end

  # Funcoes auxiliares
  defp assign_message_form(socket, %Message{} = message) do
    scope = socket.assigns.current_scope
    changeset = Messages.change_message(scope, message)
    assign(socket, :form, to_form(changeset))
  end

  defp notify_total_unread(socket) do
    total = Enum.sum_by(socket.assigns.chats, & &1.unread_count)
    push_event(socket, "update_title", %{count: total})
  end

  defp chat_display_info(chat, current_user_id) do
    if chat.type == :group do
      %{
        title: chat.title || "Grupo",
        avatar_url: nil,
        initials: "GR"
      }
    else
      # Procura o outro membro que não é o usuário logado da DM
      other_member =
        Enum.find(chat.chat_members || [], fn member -> member.user_id != current_user_id end)

      other_user = other_member && other_member.user

      username = (other_user && other_user.username) || "DM"
      avatar_url = other_user && other_user.avatar_url
      initials = String.upcase(String.slice(username, 0, 2))

      %{
        title: username,
        avatar_url: avatar_url,
        initials: initials
      }
    end
  end

  # Eventos de resposta as mensagens
  @impl true
  def handle_event("set_reply", %{"msg-id" => msg_id}, socket) do
    # Busca a mensagem do banco ou da memória para exibir os dados de resposta
    msg = Messages.get_message!(msg_id)
    {:noreply, assign(socket, :replying_to, msg)}
  end

  @impl true
  def handle_event("cancel_reply", _params, socket) do
    {:noreply, assign(socket, :replying_to, nil)}
  end

  @impl true
  def handle_event("save_message", %{"msg-id" => msg_id}, socket) do
    # Lógica para salvar na conversa "Saved Messages" do próprio usuário
    case Kgkm.Messages.save_message(msg_id) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Mensagem salva com sucesso!")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Não foi possível salvar a mensagem")}
    end
  end

  @impl true
  def handle_event("save_recorded_audio", %{"audio_data" => audio_data}, socket) do
    scope = socket.assigns.current_scope
    chat_id = socket.assigns.active_chat.id

    # Remove o cabeçalho base64 do data URL (ex: "data:audio/ogg; codecs=opus;base64,")
    [header, encoded] = String.split(audio_data, ",")
    binary_data = Base.decode64!(encoded)

    # Define o diretório de destino em priv/static/uploads
    dest_dir = Path.join([:code.priv_dir(:kgkm), "static", "uploads"])
    File.mkdir_p!(dest_dir)
    filename = "audio-#{System.unique_integer([:positive])}.ogg"
    dest_path = Path.join(dest_dir, filename)

    # Salva o arquivo no disco
    File.write!(dest_path, binary_data)
    file_url = "/uploads/#{filename}"

    # Cria a mensagem associada ao chat contento o audio gravado
    case Messages.create_message(scope, %{
           chat_id: chat_id,
           content: "voice message",
           file_url: file_url
         }) do
      {:ok, _message} ->
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Não foi possível enviar o áudio.")}
    end
  end

  @impl true
  def handle_event("open_camera_modal", _params, socket) do
    {:noreply, assign(socket, :show_camera_modal?, true)}
  end

  @impl true
  def handle_event("close_camera_modal", _params, socket) do
    {:noreply, assign(socket, :show_camera_modal?, false)}
  end

  @impl true
  def handle_event("save_captured_image", %{"image_data" => image_data}, socket) do
    scope = socket.assigns.current_scope
    chat_id = socket.assigns.active_chat.id

    # Decodifica o base64 da foto tirada
    [header, encoded] = String.split(image_data, ",")
    binary_data = Base.decode64!(encoded)
    dest_dir = Path.join([:code.priv_dir(:kgkm), "static", "uploads"])
    File.mkdir_p!(dest_dir)

    filename = "photo-#{System.unique_integer([:positive])}.jpg"
    dest_path = Path.join(dest_dir, filename)

    File.write!(dest_path, binary_data)
    file_url = "/uploads/#{filename}"

    case Messages.create_message(scope, %{
           chat_id: chat_id,
           content: "Foto tirada",
           file_url: file_url
         }) do
      {:ok, _message} ->
        {:noreply, assign(socket, :show_camera_modal?, false)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Não foi possível enviar a foto.")}
    end
  end

  @impl true
  def handle_event("open_saved_messages", _params, socket) do
    scope = socket.assigns.current_scope
    saved_msgs = Messages.list_user_saved_messages(scope)

    {:noreply,
     socket
     |> assign(:show_saved_modal?, true)
     |> assign(:saved_messages, saved_msgs)}
  end

  @impl true
  def handle_event("close_saved_messages", _params, socket) do
    {:noreply, assign(socket, :show_saved_modal?, false)}
  end

  # Ação para ir direto para o chat da mensagem salva e opcionalmente preparar resposta
  @impl true
  def handle_event("jump_to_saved_message", %{"chat-id" => chat_id, "msg-id" => msg_id}, socket) do
    scope = socket.assigns.current_scope

    # Fecha o modal e navega via patch para o chat correspondente
    msg = Messages.get_message!(msg_id)

    {:noreply,
     socket
     |> assign(:show_saved_modal?, false)
     # Opcional: Já deixa configurado para responder essa msg
     |> assign(:replying_to, msg)
     |> push_patch(to: ~p"/chats/#{chat_id}")}
  end

  @impl true
  def handle_event("toggle_mute_chat", %{"chat-id" => chat_id}, socket) do
    user_id = socket.assigns.current_scope.user.id

    # Atualiza ou alterna o status de mudo na tabela de participantes
    case Chats.toggle_mute_participant(chat_id, user_id) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Preferências de notificação atualizadas.")
          |> assign(:chats, Chats.list_user_chats(socket.assigns.current_scope))

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Não foi possível mutar o chat")}
    end
  end

  @impl true
  def handle_event("clear_chat_history", %{"chat-id" => chat_id}, socket) do
    user_id = socket.assigns.current_scope.user.id

    # Define um timestamp 'cleared_at' para o usuário neste chat,
    # fazendo com que mensagens anteriores a este momento fiquem invisíveis apenas para para ele
    case Chats.clear_history_for_user(chat_id, user_id) do
      {:ok, _} ->
        # Recarrega os chats e limpa o stream de mensagens ativas se for o chat atual
        socket =
          socket
          |> put_flash(:info, "Conversa limpa com sucesso")
          # Recarrega a lista de chats da sidebar
          |> assign(:chats, Chats.list_user_chats(socket.assigns.current_scope))
          # Se o chat limpo for o que está aberto atualmente, limpa o stream de mensagens
          |> then(fn s ->
            if s.assigns[:active_chat] && s.assigns.active_chat.id == chat_id do
              stream(s, :messages, [], reset: true)
            else
              s
            end
          end)

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erro ao limpar conversa")}
    end
  end

  @impl true
  def handle_event("delete_chat_for_me", %{"chat-id" => chat_id}, socket) do
    user_id = socket.assigns.current_scope.user.id

    # Oculta o chat da lista pessoal do usuário (soft delete)
    case Chats.hide_chat_for_user(chat_id, user_id) do
      {:ok, _} ->
        socket =
          if socket.assigns.active_chat && socket.assigns.active_chat.id == chat_id do
            push_patch(socket, to: "~p/chats")
          else
            socket
          end
          |> put_flash(:info, "Chat removido da sua lista")
          |> assign(:chats, Chats.list_user_chats(socket.assigns.current_scope))
          |> assign(:active_chat, nil)

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Erro ao excluir chat.")}
    end
  end

  defp load_user_chats(scope) do
    Chats.list_user_chats(scope)
    |> Enum.map(fn chat ->
      # Garante que unread_count exista e seja numerico
      Map.put_new(chat, :unread_count, 0)
    end)
  end

  @impl true
  def handle_info({:typing, username}, socket) do
    current_username = socket.assigns.current_scope.user.username

    # Ignora se foi o proprio usuario que disparou
    if username == current_username do
      {:noreply, socket}
    else
      socket = assign(socket, :typing_user, username)

      # Opcional: Limpa o texto "digitando..." apos 3 segundos sem novos eventos
      Process.send_after(self(), :clear_typing, 3000)
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:clear_typing, socket) do
    {:noreply, assign(socket, :typing_user, nil)}
  end

  @impl true
  def handle_info({:messages_read, reader_user_id}, socket) do
    current_user_id = socket.assigns.current_scope.user.id

    # Se quem leu foi o outro usuario, atualizamos o status visual das nossas mensagens
    if reader_user_id != current_user_id do
      # Atualiza as mensagens na stream ou recarrega o stream de forma limpa
      chat_id = socket.assigns.active_chat.id
      messages = Messages.list_mesages(chat_id, current_user_id)

      {:noreply, stream(socket, :messages, messages, reset: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_other, socket), do: {:noreply, socket}
end
