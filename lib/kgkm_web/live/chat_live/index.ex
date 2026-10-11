defmodule KgkmWeb.ChatLive.Index do
  use KgkmWeb, :live_view

  alias Kgkm.Accounts
  alias Kgkm.Chats
  alias Kgkm.Messages
  alias Kgkm.Messages.Message

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="chat-app-root"
      phx-hook="PageTitle"
      class="h-screen w-screen overflow-hidden bg-white dark:bg-gray-900 relative"
    >
      <%!-- Componentes de Flash Notices nativos do seu CoreComponents --%>
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
      <div class="chat-layout">
        <!-- Sidebar Principal -->
        <aside class="chat-sidebar">
          <!-- Cabeçalho do Usuário, Botão Novo Grupo e Search Bar -->
          <div class="p-3 border-b border-gray-200 dark:border-gray-800 flex items-center gap-2 bg-white dark:bg-gray-900">
            <!-- DROPDOWN COMPONENT DO CORE COMPONENTS -->
            <.dropdown id="main-menu">
              <:trigger>
                <button class="p-2 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300 transition">
                  <.icon name="hero-bars-3" class="w-6 h-6" />
                </button>
              </:trigger>

              <:item phx-click="open_group_modal">
                <.icon name="hero-user-group" class="w-5 h-5 text-indigo-500" />
                <span>Novo Grupo</span>
              </:item>

              <:item phx-click="open_saved_messages">
                <.icon name="hero-bookmark" class="w-5 h-5 text-amber-500" />
                <span>Conversas Salvas</span>
              </:item>

              <:item navigate={~p"/users/settings"}>
                <.icon name="hero-user" class="w-5 h-5 text-gray-500" />
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
                Contatos
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
              <% info = chat_display_info(chat, @current_scope.user.id) %>
              <.link
                patch={~p"/chats/#{chat.id}"}
                class={"flex items-center gap-3 p-2.5 rounded-2xl transition #{if @active_chat && @active_chat.id == chat.id, do: "bg-orange-500 text-white dark:bg-indigo-600", else: "hover:bg-gray-100 dark:hover:bg-gray-800"}"}
              >
                <!-- Avatar Dinâmico (Foto ou Iniciais) -->
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
                
    <!-- BADGE DE NÂO LIDAS -->
                <%= if chat.unread_count > 0 do %>
                  <span class="bg-orange-500 dark:bg-indigo-500 text-white text-[11px] font-bold px-2 py-0.5 rounded-full shrink-0">
                    {chat.unread_count}
                  </span>
                <% end %>
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
            <% active_info = chat_display_info(@active_chat, @current_scope.user.id) %>
            <!-- Subcabeçalho da Conversa -->
            <div class="p-3 border-b bg-gray-200 dark:border-gray-800 bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm flex items-center gap-3 z-10">
              <div class="user-avatar overflow-hidden">
                <%= if active_info.avatar_url do %>
                  <img src={active_info.avatar_url} class="w-full h-full object-cover" alt="Avatar" />
                <% else %>
                  {active_info.initials}
                <% end %>
              </div>
              <div>
                <h3 class="text-sm font-bold leading-tight">{active_info.title}</h3>
                <p class="text-xs text-gray-400">em tempo real</p>
              </div>
            </div>
            
    <!-- Feed de Mensages (Stream) -->
            <div
              id="messages-feed"
              phx-hook="ChatScroll"
              phx-update="stream"
              class="flex-1 p-4 sm:p-6 overflow-y-auto flex flex-col space-y-2"
            >
              <div class="chat-date-badge">Hoje</div>
              <div
                :for={{dom_id, msg} <- @streams.messages}
                id={"message-#{msg.id}"}
                class={"flex flex-col group relative #{if msg.user_id == @current_scope.user.id, do: "items-end", else: "items-start"}"}
              >
                <%= if msg.user_id != @current_scope.user.id do %>
                  <span class="text-[10px] text-gray-400 ml-2 mb-0.5">{msg.user.username}</span>
                <% end %>

                <div class="flex items-center gap-1.5 max-w-[85%] md:max-w-md">
                  <!-- Se for mensagem enviada por mim, o menu de ações fica à esquerda do balão -->
                  <%= if msg.user_id == @current_scope.user.id do %>
                    <.msg_actions_dropdown msg_id={msg.id} msg_content={msg.content} is_me={true} />
                  <% end %>

                  <div class={
                    if msg.user_id == @current_scope.user.id,
                      do: "msg-bubble-sent",
                      else: "msg-bubble-received"
                  }>
                    <!-- Se a mensagem for uma resposta a outra, exibe o bloco citado -->
                    <%= if Map.get(msg, :reply_to) && msg.reply_to do %>
                      <div
                        class="mb-1.5 p-1.5 rounded-lg bg-black/10 dark:bg-white/10 border-l-2 border-orange-400 dark:border-indigo-400 text-xs cursor-pointer hover:bg-black/15 dark:hover:bg-white/15 transition"
                        onclick={"window.dispatchEvent(new CustomEvent('scroll_to_message', { detail: { msgId: '#{msg.reply_to.id}' } }))"}
                      >
                        <p class="font-bold opacity-90">{msg.reply_to.user.username}</p>
                        <p class="truncate opacity-75">{msg.reply_to.content}</p>
                      </div>
                    <% end %>
                    
    <!-- Renderiza imagem  ou arquivo se houver file_url -->
                    <%= if msg.file_url do %>
                      {ext = String.downcase(Path.extname(msg.file_url))}
                      <!-- Se for IMAGEM -->
                      <%= if ext in [".jpg", ".jpeg", ".png", ".webp", ".gif"] do %>
                        <div class="mb-2 rounded-2xl overflow-hidden max-w-xs cursor-pointer group/img relative">
                          <img
                            src={msg.file_url}
                            class="w-full h-auto object-cover rounded-2xl transition group-hover/img:scale-105"
                            alt="Foto anexada"
                            onclick={"window.open('#{msg.file_url}', '_blank')"}
                          />
                          <a
                            href={msg.file_url}
                            download
                            class="absolute bottom-2 right-2 p-1.5 bg-black/60 text-white rounded-full opacity-0 group-hover/img:opacity-100 transition shadow-lg"
                            title="Baixar Imagem"
                          >
                            <.icon name="hero-arrow-down-tray" class="w-4 h-4" />
                          </a>
                        </div>
                        
    <!-- Se for Áudio (Música gravada ou enviada) -->
                      <% else %>
                        <%= if ext in [".mp3", ".wav", ".ogg"] do %>
                          <div class="mb-2 min-w-[200px]">
                            <audio controls class="w-full h-10">
                              <source src={msg.file_url} /> Seu navegador não suporta áudio.
                            </audio>
                          </div>
                          <!-- Se for Documento (PDF, DOCX, etc) -->
                        <% else %>
                          <div class="mb-2 p-3 rounded-2xl bg-black/5 dark:bg-white/5 border border-black/10 dark:border-white/10 flex items-center justify-between gap-3 min-w[220px]">
                            <div class="flex items-center gap-2.5 min-w-0">
                              <div class="p-2.5 rounded-xl bg-orange-500/10 dark:bg-indigo-500/20 text-orange-500 dark:text-indigo-400 shrink-0">
                                <.icon name="hero-document-text" class="w-6 h-6" />
                              </div>
                              <div class="min-w-0">
                                <p class="text-xs font-bold  truncate text-gray-800 dark:text-gray-200">
                                  {Path.basename(msg.file_url)}
                                </p>
                                <span class="text-[10px] text-gray-400 uppercase font-semibold">
                                  Documento
                                </span>
                              </div>
                            </div>

                            <div class="flex items-center gap-1 shrink-0">
                              <!-- Abrir no Navegador -->
                              <a
                                href={msg.file_url}
                                target="_blank"
                                class="p-1.5 rounded-lg hover:bg-black/10 dark:hover:bg-white/10 text-gray-500 transition"
                                title="Abrir no navegador"
                              >
                                <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4" />
                              </a>
                              <!-- Download Direto -->
                              <a
                                href={msg.file_url}
                                download
                                class="p-1.5 rounded-lg hover:bg-black/10 dark:hover:bg-white/10 text-gray-500 transition"
                                title="Baixar arquivo"
                              >
                                <.icon name="hero-arrow-down-tray" class="w-4 h-4" />
                              </a>
                            </div>
                          </div>
                        <% end %>
                      <% end %>
                    <% end %>
                    <p class="break-words">{msg.content}</p>
                    <div class="text-[9px] text-right mt-1 opacity-75">
                      {Calendar.strftime(msg.inserted_at, "%H:%M")}
                    </div>
                  </div>
                  
    <!-- Se for mensagem recebida, o menu de ações fica à direita -->
                  <%= if msg.user_id != @current_scope.user.id do %>
                    <.msg_actions_dropdown msg_id={msg.id} msg_content={msg.content} is_me={false} />
                  <% end %>
                </div>
              </div>
            </div>
            
    <!-- Caixinha de Citação/Resposta -->

            <%= if @replying_to do %>
              <div class="px-4 py-2 bg-gray-100 dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700 flex items-center justify-between">
                <div class="flex items-center gap-2 border-l-2 border-orange-500 dark:border-indigo-500 pl-2 text-xs min-w-0">
                  <div>
                    <p class="font-bold text-orange-500 dark:text-indigo-500">
                      Respondendo a {@replying_to.user.username}
                    </p>
                    <p class="text-gray-500 dark:text-gray-400 truncate">{@replying_to.content}</p>
                  </div>
                </div>
                <button
                  phx-click="cancel_reply"
                  class="text-gray-400 hover:text-gray-600 font-bold text-sm"
                >
                  x
                </button>
              </div>
            <% end %>
            
    <!-- Área de Preview do Arquivo selecionado antes de enviar -->
            <%= for entry <- @uploads.chat_file.entries do %>
              <div class="px-4 py-2 bg-gray-50 dark:bg-gray-800/80 border-t border-gray-200 dark:border-gray-700 flex items-center justify-between">
                <div class="flex items-center gap-2 text-xs truncate">
                  <.icon
                    name="hero-paper-clip"
                    class="w-4 h-4 text-orange-500 dark:text-indigo-500 shrink-0"
                  />
                  <span class="font-medium truncate">{entry.client_name}</span>
                  <span class="text-gray-400">
                    ({Float.round(entry.client_size / 1024 / 1024, 1)} MB)
                  </span>
                </div>

                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  class="text-gray-400 hover:text-red-500"
                >
                  <.icon name="hero-x-mark" class="w-4 h-4" />
                </button>
              </div>
            <% end %>
            
    <!-- Botão flutuante para descer ao fim do chat -->
            <div class="absolute bottom-20 right-6 z-20">
              <button
                type="button"
                id="scroll-to-bottom-btn"
                class="hidden items-center justify-center p-3 rounded-full bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-200 shadow-xl border border-gray-200 dark:border-gray-700 hover:scale-105 transition cursor-pointer"
                title="Ir para mensagens recentes"
              >
                <.icon name="hero-arrow-down" class="w-5 h-5 text-orange-500 dark:text-indigo-400" />
              </button>
            </div>
            <!-- Input de Envio de Mensagem e Anexos -->
            <div class="p-3 bg-white dark:bg-gray-900 border-t border-gray-200 dark:border-gray-800">
              <.form
                for={@form}
                id="message-form"
                phx-change="validate"
                phx-submit="save"
                class="flex items-center gap-2"
              >
                
    <!-- Botão de anexar arquivos -->
                <label class="p-2.5 rounded-full hover:bg-gray-100 dark:bg-gray-800 text-gray-500 cursor-pointer shrink-0 transition">
                  <.icon name="hero-paper-clip" class="w-5 h-5" />
                  <.live_file_input upload={@uploads.chat_file} class="sr-only" />
                </label>
                <button
                  type="button"
                  phx-click="open_camera_modal"
                  class="p-2.5 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 cursor-pointer shrink-0 transition"
                  title="Tirar Foto / Vídeo"
                >
                  <.icon name="hero-camera" class="w-5 h-5" />
                </button>
                <div class="flex-1">
                  <.input
                    type="text"
                    field={@form[:content]}
                    placeholder="Escreva uma mensagem..."
                    autocomplete="off"
                    class="w-full text-sm px-4 py-2.5 rounded-full border-none bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
                
    <!-- Botão Dinâmico: Se vazio e sem arquivo -> Microfone | Se ou com arquivo -> Enviar -->
                <%= if (@form[:content].value in [nil, ""]) && @uploads.chat_file.entries == [] do %>
                  <button
                    type="button"
                    id="audio-mic-button"
                    phx-hook="MediaRecorder"
                    class="p-3 rounded-full bg-gray-100 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700 text-gray-600 dark:text-gray-300 transition shrink-0 cursor-pointer"
                    title="Gravar Áudio"
                  >
                    <.icon
                      name="hero-microphone"
                      class="w-5 h-5 text-orange-500 dark:text-indigo-400"
                    />
                  </button>
                <% else %>
                  <.button
                    phx-disable-with="..."
                    variant="primary"
                    class="!rounded-full !p-3 shrink-0"
                  >
                    <.icon name="hero-paper-airplane" class="w-4 h-4" />
                  </.button>
                <% end %>
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

    <!-- MODAL DE CAPTURA DE CÂMERA -->
    <%= if @show_camera_modal? do %>
      <div class="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4">
        <div class="bg-white dark:bg-gray-900 p-4 rounded-2xl w-full max-w-lg space-y-4 shadow-2xl border border-gray-200 dark:border-gray-800">
          <div class="flex justify-between items-center border-b border-gray-200 dark:border-gray-800 pb-2">
            <h3 class="text-sm font-bold text-gray-800 dark:text-gray-200">
              Tirar Foto / Gravar Vídeo
            </h3>
            <button
              phx-click="close_camera_modal"
              class="text-gray-400 hover:text-red-500 font-bold text-sm"
            >
              x
            </button>
          </div>
          
    <!-- Elementos de Vídeo e Hook JS -->
          <div
            id="camera-container"
            phx-hook="CameraCapture"
            class="relative rounded-xl overflow-hidden bg-black aspect-video flex items-center justify-center"
          >
            <video id="camera-preview" autoplay playsinline muted class="w-full h-full object-cover">
            </video>
            <canvas id="camera-canvas" class="hidden"></canvas>
          </div>
          
    <!-- Botões de Ação da Câmera -->
          <div class="flex items-center justify-center gap-4 pt-2">
            <button
              type="button"
              id="capture-photo-btn"
              class="px-4 py-2 bg-orange-500 hover:bg-orange-600 dark:bg-indigo-600 dark:hover:bg-indigo-700 text-white text-xs font-bold rounded-xl shadow transition flex items-center gap-2 cursor-pointer"
            >
              > <.icon name="hero-camera" class="w-4 h-4" /> Tirar Foto
            </button>
          </div>
        </div>
      </div>
    <% end %>

    <!-- MODAL DE CONVERSAS SALVAS -->
    <%= if @show_saved_modal? do %>
      <div class="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
        <div class="bg-white dark:bg-gray-900 rounded-3xl w-full max-w-lg max-h-[80vh] flex flex-col shadow-2xl border border-gray-100 dark:border-gray-800 overflow-hidden">
          <!-- Cabeçalho do Modal -->
          <div class="px-6 py-4 border-b border-gray-100 dark:border-gray-800 flex justify-between items-center bg-gray-50/50 dark:bg-gray-800/50">
            <div class="flex items-center gap-2">
              <div class="p-2 rounded-xl bg-amber-500/10 text-amber-500">
                <.icon name="hero-bookmark" class="w-5 h-5" />
              </div>
              <h3 class="font-bold text-gray-800 dark:text-gray-100 text-base">Mensagens Salvas</h3>
            </div>
            <button
              phx-click="close_saved_messages"
              class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 rounded-full transition"
            >
              x
            </button>
          </div>
          
    <!-- Lista Scrollável de Mensagens Salvas -->
          <div class="flex-1 overflow-y-auto p-4 space-y-3">
            <%= if @saved_messages == [] do %>
              <div class="flex flex-col items-center justify-center py-12 text-gray-400 space-y-2">
                <.icon name="hero-bookmark" class="w-10 h-10 stroke-1 opacity-50" />
                <p class="text-xs">Nenhuma mensagem salva por enquanto</p>
                <span class="text-[10px] text-gray-400">
                  Clique em "Salvar / Pin" nas opções de qualquer mensagem
                </span>
              </div>
            <% else %>
              <div
                :for={msg <- @saved_messages}
                class="p-4 rounded-2xl bg-gray-50 dark:bg-gray-800/60 border border-gray-100 dark:border-gray-700/60 flex flex-col gap-2 hover:border-amber-500/50 transition group"
              >
                <!-- Infos do Ator e Data -->
                <div class="flex justify-between items-center text-xs">
                  <span class="font-bold text-indigo-500 dark:text-indigo-400">
                    {msg.user.username}
                  </span>
                  <span class="text-[10px] text-gray-400">
                    {Calendar.strftime(msg.inserted_at, "%d/%m/%Y às %H:%M")}
                  </span>
                </div>
                
    <!-- Conteúdo da mensagem -->
                <p class="text-xs text-gray-700 dark:text-gray-300 break-words bg-white dark:bg-gray-900/50 p-2.5 rounded-xl border border-gray-100 dark:border-gray-800">
                  {msg.content}
                </p>
                
    <!-- Ações da Mensagem Salva -->
                <div class="flex items-center justify-end gap-2 pt-1">
                  <!-- Botão Copiar -->
                  <button
                    type="button"
                    phx-click={JS.dispatch("copy_to_clipboard", detail: %{text: msg.content})}
                    class="px-3 py-1.5 rounded-xl text-xs font-medium bg-gray-200/70 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-200 flex items-center gap-1 transition"
                  >
                    <.icon name="hero-document-duplicate" class="w-3.5 h-3.5" /> Copiar
                  </button>
                  <!-- Botão Ir para o Chat / Responder -->
                  <button
                    type="button"
                    phx-click="jump_to_saved_message"
                    phx-value-chat-id={msg.chat_id}
                    phx-value-msg-id={msg.id}
                    class="px-3 py-1.5 rounded-xl text-xs font-medium bg-amber-500 hover:bg-amber-600 text-white flex items-center gap-1 transition shadow-sm"
                  >
                    <.icon name="hero-arrow-uturn-left" class="w-3.5 h-3.5" /> Ir para o Chat
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    chats =
      Chats.list_user_chats(scope)
      |> Enum.map(&Map.put_new(&1, :unread_count, 0))

    if connected?(socket) do
      # Inscreve o usuário em TODOS os chats dele para escutar mensagens em background
      Enum.each(chats, fn chat ->
        Messages.subscribe_chat_messages(chat.id)
      end)
    end

    chats_with_unread = Enum.map(chats, &Map.put(&1, :unread_count, 0))

    {:ok,
     socket
     |> assign(:chats, chats_with_unread)
     |> assign(:active_chat, nil)
     |> assign(:search_query, "")
     |> assign(:search_results, [])
     # Estados para o Modal de Grupo
     |> assign(:show_group_modal?, false)
     |> assign(:group_search_results, [])
     |> assign(:selected_group_members, [])
     |> assign(:replying_to, nil)
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

    if connected?(socket) do
      if active_chat = socket.assigns.active_chat do
        Phoenix.PubSub.unsubscribe(Kgkm.PubSub, "chat:#{active_chat.id}:messages")
      end

      Messages.subscribe_chat_messages(chat_id)
    end

    chat = Chats.get_chat!(scope, chat_id)
    messages = Messages.list_messages(chat_id)

    # Zera as mensagens não lidas do chat aberto
    updated_chats =
      Enum.map(socket.assigns.chats, fn c ->
        c = Map.put_new(c, :unread_count, 0)
        if c.id == chat_id, do: %{c | unread_count: 0}, else: c
      end)

    socket
    |> assign(:chats, updated_chats)
    |> notify_total_unread()
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

  def handle_info(_other, socket), do: {:noreply, socket}

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
end
