defmodule KgkmWeb.UserLive.Settings do
  use KgkmWeb, :live_view

  on_mount {KgkmWeb.UserAuth, :require_sudo_mode}

  alias Kgkm.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-3xl mx-auto space-y-6 pb-12">
        <!-- HEADER DO PERFIL -->
        <div class="relative overflow-hidden rounded-3xl bg-gradient-to-r from-orange-500 via-amber-500 to-yellow-500 dark:from-indigo-700 dark:via-indigo-800 dark:to-blue-900 p-6 sm:p-8 text-white shadow-md">
          <div class="flex flex-col sm:flex-row items-center gap-5 z-10 relative">
            <!-- AVATAR FORM -->
            <form
              id="avatar-form"
              phx-change="validate_avatar"
              phx-submit="save_avatar"
              class="shrink-0"
            >
              <div class="relative group w-24 h-24 sm:w-28 sm:h-28">
                <div class="w-full h-full rounded-full overflow-hidden border-4 border-white/80 dark:border-zinc-800 shadow-xl bg-zinc-100 dark:bg-zinc-800 flex items-center justify-center relative">
                  <%= if @uploads.avatar.entries != [] do %>
                    <.live_img_preview
                      entry={List.last(@uploads.avatar.entries)}
                      class="w-full h-full object-cover"
                    />
                  <% else %>
                    <img
                      src={
                        @current_user.avatar_url ||
                          "https://api.dicebear.com/7.x/bottts/svg?seed=#{@current_user.email}"
                      }
                      class="w-full h-full object-cover"
                      alt="Avatar"
                    />
                  <% end %>
                  
    <!-- Overlay e Input unificado para Abrir a seleção de arquivo -->
                  <label class="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center text-white text-[11px] font-bold cursor-pointer rounded-full">
                    <.icon name="hero-camera" class="w-5 h-5 mb-1" /> Alterar Foto
                    <.live_file_input upload={@uploads.avatar} class="sr-only" />
                  </label>
                </div>
              </div>

              <%= if @uploads.avatar.entries != [] do %>
                <div class="text-center mt-3">
                  <button
                    type="submit"
                    phx-disable-with="Salvando..."
                    class="px-3 py-1 bg-white text-orange-600 dark:bg-indigo-600 dark:text-white rounded-full text-xs font-bold shadow-md hover:bg-opacity-90 transition active:scale-95 cursor-pointer"
                  >
                    Salvar Foto
                  </button>
                </div>
              <% end %>

              <%= for entry <- @uploads.avatar.entries, error <- upload_errors(@uploads.avatar, entry) do %>
                <p class="text-xs text-red-200 mt-1 text-center font-medium">
                  {Phoenix.Naming.humanize(error)}
                </p>
              <% end %>
            </form>
            <!-- Infos do Usuario -->
            <div class="text-center sm:text-left space-y-1">
              <h1 class="text-xl sm:text-2xl font-black tracking-tight">
                Olá, {String.capitalize(List.first(String.split(@current_user.email, "@")))}!
              </h1>
              <p class="text-xs sm:text-sm text-white/80 font-medium">
                {@current_user.email}
              </p>
            </div>
          </div>
        </div>
        
    <!-- SECAO: MEUS DADOS -->
        <div class="bg-white dark:bg-zinc-900 rounded-3xl border border-zinc-200/70 dark:border-zinc-800 p-5 shadow-xs space-y-4">
          <h2 class="text-base font-extrabold text-zinc-900 dark:text-zinc-100 px-1">
            Meus Dados
          </h2>

          <div class="divide-y divide-zinc-100 dark:divide-zinc-800/60">
            <.settings_menu_item icon="hero-bell" title="Notificações" />
            <.settings_menu_item icon="hero-question-mark-circle" title="Ajuda e Suporte" />
            <.settings_menu_item icon="hero-information-circle" title="Sobre" />
          </div>
          <!-- SEÇÃO: SEGURANÇA E CONTA (Formulários E-mail e Senha) -->
          <div class="space-y-4">
            <h2 class="text-base font-extrabold text-zinc-900 dark:text-zinc-100 px-1">
              Segurança da Conta
            </h2>
            
    <!-- ALTERAR EMAIL -->
            <div class="bg-white dark:bg-zinc-900 rounded-3xl border border-zinc-200/70 dark:border-zinc-800 p-5 shadow-xs space-y-4">
              <h3 class="text-xs font-extrabold uppercase tracking-wider text-zinc-500 dark:text-zinc-400 flex items-center gap-2">
                <.icon name="hero-envelope" class="w-4 h-4 text-orange-500 dark:text-indigo-400" />
                Alterar E-mail
              </h3>

              <.form
                for={@email_form}
                id="email_form"
                phx-submit="update_email"
                phx-change="validate_email"
                class="space-y-3"
              >
                <.input
                  field={@email_form[:email]}
                  type="email"
                  label="Novo E-mail"
                  autocomplete="username"
                  spellcheck="false"
                  required
                />
                <div class="flex justify-end pt-2">
                  <.button variant="primary" phx-disable-with="Alterando...">
                    Atualizar E-mail
                  </.button>
                </div>
              </.form>
            </div>
            
    <!-- ALTERAR SENHA -->
            <div class="bg-white dark:bg-zinc-900 rounded-3xl border border-zinc-200/70 dark:border-zinc-800 p-5 shadow-xs space-y-4">
              <h3 class="text-xs font-extrabold uppercase tracking-wider text-zinc-500 dark:text-zinc-400 flex items-center gap-2">
                <.icon name="hero-key" class="w-4 h-4 text-orange-500 dark:text-indigo-400" />
                Alterar Senha
              </h3>

              <.form
                for={@password_form}
                id="password_form"
                action={~p"/users/update-password"}
                method="post"
                phx-change="validate_password"
                phx-submit="update_password"
                phx-trigger-action={@trigger_submit}
                class="space-y-3"
              >
                <input
                  name={@password_form[:email].name}
                  type="hidden"
                  id="hidden_user_email"
                  spellcheck="false"
                  value={@current_email}
                />
                <.input
                  field={@password_form[:password]}
                  type="password"
                  label="Nova Senha"
                  autocomplete="new-password"
                  spellcheck="false"
                  required
                />
                <.input
                  field={@password_form[:password_confirmation]}
                  type="password"
                  label="Confirmar Nova Senha"
                  autocomplete="new-password"
                  spellcheck="false"
                />
                <div class="flex justify-end pt-2">
                  <.button variant="primary" phx-disable-with="Salvando...">
                    Salvar Nova Senha
                  </.button>
                </div>
              </.form>
            </div>
          </div>
          
    <!-- BOTÃO DE LOGOUT (Estilo Flutter) -->
          <div class="pt-4">
            <.link
              href={~p"/users/log-out"}
              method="delete"
              class="inline-flex items-center gap-2.5 px-4 py-2.5 rounded-2xl text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-950/30 transition-colors font-bold text-sm cursor-pointer"
            >
              <.icon name="hero-arrow-right-on-rectangle" class="w-5 h-5 text-red-500" />
              <span>Sair da Conta</span>
            </.link>
          </div>
        </div>
      </div>
      
    <!-- Address Modal
      <.custom_modal id="address-modal">
        <div class="mb-5">
          <h2 class="text-lg font-bold text-zinc-900 dark:text-white flex items-center gap-2">
            <.icon name="hero-map-pin" class="w-5 h-5 text-orange-500 dark:text-indigo-500" />
            Addresses
          </h2>
        </div>

        <div
          id="address-modal-list"
          phx-update="stream"
          class="divide-y divide-zinc-100 dark:divide-zinc-800/60 max-h-[60vh] overflow-y-auto pr-1"
        >
          <div
            :for={{dom_id, addr} <- @streams.addresses}
            id={dom_id}
            class="py-3.5 flex items-center justify-between gap-4"
          >
            <div class="flex items-center gap-3 min-w-0">
              <span class="text-sm font-semibold text-zinc-800 dark:text-zinc-200 truncate">
                {addr.street}
              </span>
            </div>
          </div>
        </div>
      </.custom_modal>
      -->
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_user, user)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)
      |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 1,
        max_file_size: 4_000_000
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end

  @impl true
  def handle_event("validate_avatar", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save_avatar", _params, socket) do
    user = socket.assigns.current_scope.user

    uploaded_urls =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
        dest_dir = Path.join([:code.priv_dir(:kgkm), "static", "uploads"])
        File.mkdir_p!(dest_dir)
        filename = "avatar-#{user.id}-#{:os.system_time(:millisecond)}.jpg"
        dest_path = Path.join(dest_dir, filename)

        File.cp!(path, dest_path)
        {:ok, "/uploads/#{filename}"}
      end)

    case uploaded_urls do
      [avatar_url | _] ->
        case Accounts.update_user_avatar(user, avatar_url) do
          {:ok, updated_user} ->
            {:noreply,
             socket
             |> put_flash(:info, "Foto de perfil atualizada com sucesso!")
             |> assign(:current_user, updated_user)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Erro ao salvar foto de perfil")}
        end

      _ ->
        {:noreply, socket}
    end
  end
end
