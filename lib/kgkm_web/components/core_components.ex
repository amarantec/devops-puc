defmodule KgkmWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: KgkmWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr(:id, :string, doc: "the optional id of flash container")
  attr(:flash, :map, default: %{}, doc: "the map of flash messages to display")
  attr(:title, :string, default: nil)
  attr(:kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")

  slot(:inner_block, doc: "the optional inner block that renders the flash message")

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr(:rest, :global, include: ~w(href navigate patch method download name value disabled))
  attr(:class, :string)
  attr(:variant, :string, values: ~w(primary))
  slot(:inner_block, required: true)

  def button(%{rest: rest} = assigns) do
    variants = %{"primary" => "btn-primary", nil => "btn-primary btn-soft"}

    assigns =
      assign_new(assigns, :class, fn ->
        ["btn", Map.fetch!(variants, assigns[:variant])]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr(:id, :any, default: nil)
  attr(:name, :any)
  attr(:label, :string, default: nil)
  attr(:value, :any)

  attr(:type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week)
  )

  attr(:field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"
  )

  attr(:errors, :list, default: [])
  attr(:checked, :boolean, doc: "the checked flag for checkbox inputs")
  attr(:prompt, :string, default: nil, doc: "the prompt for select inputs")
  attr(:options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2")
  attr(:multiple, :boolean, default: false, doc: "the multiple flag for select inputs")
  attr(:class, :string, default: nil, doc: "the input class to use over defaults")
  attr(:error_class, :string, default: nil, doc: "the input error class to use over defaults")

  attr(:rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)
  )

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label>
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@class || "w-full select", @errors != [] && (@error_class || "select-error")]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class || "w-full textarea",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class || "w-full input",
            @errors != [] && (@error_class || "input-error")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot(:inner_block, required: true)
  slot(:subtitle)
  slot(:actions)

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, default: nil, doc: "the function for generating the row id")
  attr(:row_click, :any, default: nil, doc: "the function for handling phx-click on each row")

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"
  )

  slot :col, required: true do
    attr(:label, :string)
  end

  slot(:action, doc: "the slot for showing user actions in the last table column")

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr(:title, :string, required: true)
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr(:name, :string, required: true)
  attr(:class, :string, default: "size-4")

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(KgkmWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(KgkmWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Renders a dropdown menu component.

  ## Examples
    <.dropdown id="profile-menu">
      <:trigger>
        <button class="btn btn-ghost btn-circle">
          <.icon name="hero-bars-3" class="size-6" />
        </button>
      </:trigger>
      <:item navigate={~p"/users/settings"}>
        <.icon name="hero-cog-6-tooth" class="size-5" /> Settings
      </:item>
      <:item phx-click="open_group_modal">
        <.icon name="hero-user-group" class="size-5" /> Novo Grupo
      </:item>
    </.dropdown>
  """
  attr(:id, :string, required: true)
  attr(:class, :string, default: nil)

  slot(:trigger, required: true)

  slot :item do
    attr(:navigate, :string)
    attr(:patch, :string)
    attr(:href, :string)
    attr(:method, :string)
    attr(:class, :string)
    attr(:"phx-click", :string)
  end

  def dropdown(assigns) do
    ~H"""
    <div id={@id} class={["dropdown dropdown-bottom dropdown-start", @class]}>
      <div tabindex="0" role="button">
        {render_slot(@trigger)}
      </div>
      <ul
        tabindex="0"
        class="dropdown-content menu z-50 p-2 shadow-2xl bg-base-100 dark:bg-gray-800 text-base-content rounded-2xl w-60 border border-base-200 dark:border-gray-700/60 mt-2 space-y-1"
      >
        <li :for={item <- @item}>
          <.link
            :if={item[:navigate] || item[:patch] || item[:href]}
            navigate={item[:navigate]}
            patch={item[:patch]}
            href={item[:href]}
            method={item[:method]}
            class={[
              "flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-base-200 dark:hover:bg-gray-700/60 font-medium text-sm transition",
              item[:class]
            ]}
          >
            {render_slot(item)}
          </.link>
          <button
            :if={!item[:navigate] && !item[:patch] && !item[:href]}
            type="button"
            class={[
              "w-full flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-base-200 dark:hover:bg-gray-700/60 font-medium text-sm text-left transition",
              item[:class]
            ]}
            {Map.take(item, [:id, :name, :value, :"phx-click", :"phx-target", :"phx-value-id", :"phx-value-user-id", :"phx-value-username"])}
          >
            {render_slot(item)}
          </button>
        </li>
      </ul>
    </div>
    """
  end

  # --- COMPONENTE AUXILIAR PARA ITENS DE MENU ---
  attr(:icon, :string, required: true)
  attr(:title, :string, required: true)
  attr(:navigate, :string, default: nil)

  def settings_menu_item(assigns) do
    ~H"""
    <.link
      navigate={@navigate || "#"}
      class="flex items-center justify-between py-3.5 px-2 group hover:bg-zinc-50 dark:hover:bg-zinc-800/40 rounded-xl transition-colors cursor-pointer"
    >
      <div class="flex items-center gap-3.5">
        <div class="p-2 rounded-xl bg-zinc-100 dark:bg-zinc-800 text-zinc dark:text-zinc-300 group-hover:text-orange-500 dark:group-hover:text-indigo-400 transition-colors">
          <.icon name={@icon} class="w-5 h-5" />
        </div>
        <span class="text-sm font-semibold text-zinc-800 dark:text-zinc-200">
          {@title}
        </span>
      </div>
      <.icon
        name="hero-chevron-right"
        class="w-4 h-4 text-zinc-400 group-hover:translate-x-0.5 transition-transform"
      />
    </.link>
    """
  end

  # --- COMPONENT MODAL ---
  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)
  attr(:on_cancel, :any, default: nil)
  slot(:inner_block, required: true)

  def custom_modal(assigns) do
    ~H"""
    <div
      id={@id}
      class={["relative z-50 hidden", !@show && "hidden"]}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
    >
      
    <!-- Backdrop (fundo escurecido com blur suave) -->
      <div
        id="{@id}-bg"
        class="fixed inset-0 bg-zinc-950/60 backdrop-blur-md transition-opacity duration-200 opacity-0"
        aria-hidden="true"
        phx-click={@on_cancel || hide_modal(@id)}
      />
      
    <!-- Container de alinhamento -->
      <div class="fixed inset-0 z-10 overflow-y-auto p-4 sm:p-6 md:p-12 flex items-center justify-center">
        <!-- corpo do modal -->
        <div
          id={"#{@id}-container"}
          class="relative transform overflow-hidden rounded-3xl bg-white dark:bg-zinc-900 p-5 sm:p-7 shadow-2xl transition-all w-full md:max-w-3xl lg:max-w-4xl border border-zinc-200/60 dark:border-zinc-800 scale-95 opacity-0 duration-300"
        >
          <!-- Botão de fechar no canto superior direito -->
          <button
            type="button"
            phx-click={@on_cancel || hide_modal(@id)}
            class="absolute right-4 top-4 z-20 text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-200 p-1.5 rounded-full hover:bg-zinc-100 dark:hover:bg-zinc-800 transition-colors focus:outline-none cursor-pointer"
          >
            <.icon name="hero-x-mark" class="w-5 h-5" />
          </button>
          
    <!-- Slot, onde entra o conteudo -->
          <div class="mt-10">
            {render_slot(@inner_block)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  # --- FUNÇÕES JS PARA REPLICAR O COMPORTAMENTO DO PHOENIX ---
  def show_modal(id) do
    JS.show(to: "##{id}")
    |> JS.transition({"transition-all ease-out duration-300", "opacity-0", "opacity-100"},
      to: "##{id}-bg"
    )
    |> JS.transition(
      {"transition-all ease-out duration-300", "scale-95 opacity-0", "scale-100 opacity-100"},
      to: "##{id}-container"
    )
  end

  def hide_modal(id) do
    JS.transition({"transition-all ease-in duration-200", "opacity-100", "opacity-0"},
      to: "##{id}-bg"
    )
    |> JS.transition(
      {"transition-all ease-in duration-200", "scale-100 opacity-100", "scale-95 opacity-0"},
      to: "##{id}-container"
    )
    |> JS.hide(to: "##{id}", transition: {"transition duration-200", "block", "hidden"})
  end

  @doc """
  Menu suspenso de ações de mensagem (Responder, Copiar, Salvar)
  """
  attr(:msg_id, :string, required: true)
  attr(:msg_content, :string, required: true)
  attr(:is_me, :boolean, default: false)

  def msg_actions_dropdown(assigns) do
    ~H"""
    <div class={[
      "dropdown relative shrink-0",
      if(@is_me, do: "dropdown-left dropdown-end", else: "dropdown-right dropdown-start")
    ]}>
      <div
        tabindex="0"
        role="button"
        class="p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 cursor-pointer rounded-full transition-colors"
      >
        <.icon name="hero-ellipsis-vertical" class="w-4 h-4" />
      </div>
      <ul
        tabindex="0"
        class="dropdown-content menu z-50 p-1 shadow-2xl bg-white dark:bg-gray-800 rounded-xl w-40 border border-gray-100 dark:border-gray-700 text-xs space-y-0.5"
      >
        <li>
          <button
            type="button"
            phx-click="set_reply"
            phx-value-msg-id={@msg_id}
            class="flex items-center gap-2 py-1.5 px-2 hover:bg-gray-100 dark:hover:bg-gray-700/60 rounded-lg"
          >
            <.icon name="hero-arrow-uturn-left" class="w-3.5 h-3.5 text-indigo-500" />
            <span>Responder</span>
          </button>
        </li>
        <li>
          <button
            type="button"
            phx-click={JS.dispatch("copy_to_clipboard", detail: %{text: @msg_content})}
            class="flex items-center gap-2 py-1.5 hover:bg-gray-100 dark:hover:bg-gray-700/60 rounded-lg"
          >
            <.icon name="hero-document-duplicate" class="w-3.5 h-3.5 text-gray-500" />
            <span>Copiar</span>
          </button>
        </li>
        <li>
          <button
            type="button"
            phx-click="save_message"
            phx-value-msg-id={@msg_id}
            class="flex items-center gap-2 py-1.5 px-2 hover:bg-gray-100 dark:hover:bg-gray-700/60 rounded-lg"
          >
            <.icon name="hero-bookmark" class="w-3.5 h-3.5 text-amber-500" />
            <span>Salvar / Pin</span>
          </button>
        </li>
      </ul>
    </div>
    """
  end

  @doc """
  Modal de Criação de Grupo.
  """
  attr(:show, :boolean, default: false)
  attr(:group_search_results, :list, default: [])
  attr(:selected_group_members, :list, default: [])

  def group_modal(assigns) do
    ~H"""
    <div class={["modal-backdrop", if(!@show, do: "hidden")]}>
      <div class="modal-container max-w-md">
        <div class="modal-header">
          <div class="flex items-center gap-2">
            <div class="p-2 rounded-xl bg-indigo-500/10 text-indigo-500">
              <.icon name="hero-user-group" class="w-5 h-5" />
            </div>
            <h3 class="font-bold text-gray-800 dark:text-gray-100 text-base">Criar Novo Grupo</h3>
          </div>
          <button
            type="button"
            phx-click="close_group_modal"
            class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 rounded-full transition cursor-pointer"
          >
            ✕
          </button>
        </div>

        <div class="modal-body">
          <.form for={%{}} phx-submit="create_group" class="space-y-4">
            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-gray-500 mb-1">
                Nome do Grupo
              </label>
              <input
                type="text"
                name="group_title"
                placeholder="ex: Projeto Elixir"
                required
                class="w-full text-sm rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 p-2.5 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-indigo-500"
              />
            </div>

            <div>
              <label class="block text-xs font-semibold uppercase tracking-wider text-gray-500 mb-1">
                Buscar Membro por Tag/Username
              </label>
              <input
                type="text"
                phx-keyup="search_group_member"
                name="member_query"
                placeholder="ex: alice#2002"
                class="w-full text-sm rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 p-2.5 text-gray-900 dark:text-gray-100 mb-2 focus:ring-2 focus:ring-indigo-500"
                autocomplete="off"
              />

              <%= if @group_search_results != [] do %>
                <div class="border border-gray-200 dark:border-gray-700 rounded-xl p-2 bg-gray-50 dark:bg-gray-800 max-h-32 overflow-y-auto mb-2 space-y-1">
                  <div
                    :for={user <- @group_search_results}
                    class="flex justify-between items-center text-xs p-1.5 hover:bg-gray-100 dark:hover:bg-gray-700/50 rounded-lg transition"
                  >
                    <span class="text-gray-800 dark:text-gray-200 font-medium">
                      {user.username}#{user.tag}
                    </span>
                    <.button
                      type="button"
                      phx-click="add_member_to_group"
                      phx-value-user-id={user.id}
                      phx-value-username={user.username}
                      class="text-[10px] py-1 px-2 cursor-pointer !rounded-lg"
                    >
                      <.icon name="hero-plus" /> Adicionar
                    </.button>
                  </div>
                </div>
              <% end %>

              <div class="text-xs font-semibold text-gray-500 mb-1">Membros Selecionados:</div>
              <div class="flex flex-wrap gap-1.5 border border-gray-200 dark:border-gray-700 p-2.5 rounded-xl min-h-[44px] bg-gray-50/50 dark:bg-gray-800/30">
                <span class="bg-indigo-100 dark:bg-indigo-950 text-indigo-800 dark:text-indigo-300 text-xs px-2.5 py-1 rounded-lg font-medium">
                  Você (criador)
                </span>
                <span
                  :for={member <- @selected_group_members}
                  class="bg-gray-200 dark:bg-gray-700 text-gray-800 dark:text-gray-200 text-xs px-2.5 py-1 rounded-lg flex items-center gap-1 font-medium"
                >
                  {member.username}
                  <button
                    type="button"
                    phx-click="remove_member_from_group"
                    phx-value-user-id={member.id}
                    class="text-red-500 font-bold cursor-pointer hover:scale-110 transition"
                  >
                    ✕
                  </button>
                </span>
              </div>
            </div>

            <div class="flex justify-end gap-2 pt-3 border-t border-gray-100 dark:border-gray-800">
              <.button
                type="button"
                phx-click="close_group_modal"
                class="bg-gray-200 hover:bg-gray-300 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-800 dark:text-gray-200 cursor-pointer !rounded-xl"
              >
                Cancelar
              </.button>
              <.button type="submit" variant="primary" class="cursor-pointer !rounded-xl">
                Criar Grupo
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Modal de Captura de Câmera.
  """
  attr(:show, :boolean, default: false)

  def camera_modal(assigns) do
    ~H"""
    <div class={["modal-backdrop", if(!@show, do: "hidden")]}>
      <div class="modal-container max-w-lg p-4 space-y-4">
        <div class="modal-header !px-2 !py-2">
          <div class="flex items-center gap-2">
            <div class="p-2 rounded-xl bg-orange-500/10 text-orange-500">
              <.icon name="hero-camera" class="w-5 h-5" />
            </div>
            <h3 class="text-sm font-bold text-gray-800 dark:text-gray-200">
              Tirar Foto / Gravar Vídeo
            </h3>
          </div>
          <button
            type="button"
            phx-click="close_camera_modal"
            class="text-gray-400 hover:text-red-500 font-bold text-sm cursor-pointer p-2"
          >
            ✕
          </button>
        </div>

        <div
          id="camera-container"
          phx-hook="CameraCapture"
          class="relative rounded-2xl overflow-hidden bg-black aspect-video flex items-center justify-center border border-gray-200 dark:border-gray-800"
        >
          <video id="camera-preview" autoplay playsinline muted class="w-full h-full object-cover">
          </video>
          <canvas id="camera-canvas" class="hidden"></canvas>
        </div>

        <div class="flex items-center justify-center gap-4 pt-2">
          <button
            type="button"
            id="capture-photo-btn"
            class="px-5 py-2.5 bg-orange-500 hover:bg-orange-600 dark:bg-indigo-600 dark:hover:bg-indigo-700 text-white text-xs font-bold rounded-xl shadow-md transition flex items-center gap-2 cursor-pointer"
          >
            <.icon name="hero-camera" class="w-4 h-4" /> Tirar Foto
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Modal de Conversas Salvas.
  """
  attr(:show, :boolean, default: false)
  attr(:saved_messages, :list, default: [])

  def saved_messages_modal(assigns) do
    ~H"""
    <div class={["modal-backdrop", if(!@show, do: "hidden")]}>
      <div class="modal-container max-w-lg max-h-[80vh]">
        <div class="modal-header">
          <div class="flex items-center gap-2">
            <div class="p-2 rounded-xl bg-amber-500/10 text-amber-500">
              <.icon name="hero-bookmark" class="w-5 h-5" />
            </div>
            <h3 class="font-bold text-gray-800 dark:text-gray-100 text-base">Mensagens Salvas</h3>
          </div>
          <button
            type="button"
            phx-click="close_saved_messages"
            class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 rounded-full transition cursor-pointer"
          >
            ✕
          </button>
        </div>

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
              <div class="flex justify-between items-center text-xs">
                <span class="font-bold text-indigo-500 dark:text-indigo-400">
                  {msg.user.username}
                </span>
                <span class="text-[10px] text-gray-400">
                  {Calendar.strftime(msg.inserted_at, "%d/%m/%Y às %H:%M")}
                </span>
              </div>

              <p class="text-xs text-gray-700 dark:text-gray-300 break-words bg-white dark:bg-gray-900/50 p-2.5 rounded-xl border border-gray-100 dark:border-gray-800">
                {msg.content}
              </p>

              <div class="flex items-center justify-end gap-2 pt-1">
                <button
                  type="button"
                  phx-click={JS.dispatch("copy_to_clipboard", detail: %{text: msg.content})}
                  class="px-3 py-1.5 rounded-xl text-xs font-medium bg-gray-200/70 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-200 flex items-center gap-1 transition cursor-pointer"
                >
                  <.icon name="hero-document-duplicate" class="w-3.5 h-3.5" /> Copiar
                </button>
                <button
                  type="button"
                  phx-click="jump_to_saved_message"
                  phx-value-chat-id={msg.chat_id}
                  phx-value-msg-id={msg.id}
                  class="px-3 py-1.5 rounded-xl text-xs font-medium bg-amber-500 hover:bg-amber-600 text-white flex items-center gap-1 transition shadow-sm cursor-pointer"
                >
                  <.icon name="hero-arrow-uturn-left" class="w-3.5 h-3.5" /> Ir para o Chat
                </button>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders an individual dropdown menu for chat actions (mute, clear, delete).
  """
  attr :chat_id, :string, required: true
  attr :is_muted?, :boolean, default: false

  def chat_actions_dropdown(assigns) do
    ~H"""
    <div class="dropdown dropdown-end shrink-0">
      <div
        tabindex="0"
        role="button"
        class="p-1.5 rounded-full hover:bg-black/10 dark:hover:bg-white/10 text-gray-400 cursor-pointer"
      >
        <.icon name="hero-ellipsis-vertical" class="w-4 h-4" />
      </div>
      <ul
        tabindex="0"
        class="dropdown-content menu z-50 p-1 shadow-2xl bg-white dark:bg-gray-800 rounded-xl w-44 border border-gray-100 dark:border-gray-700 text-xs space-y-0.5"
      >
        <li>
          <button
            type="button"
            phx-click={
              JS.push("toggle_mute_chat", value: %{"chat-id" => @chat_id})
              |> JS.dispatch("click", to: "body")
            }
            class="flex items-center gap-2 py-1.5 px-2 hover:bg-gray-100 dark:hover:bg-gray-700/60 rounded-lg w-full text-left"
          >
            <.icon
              name={if @is_muted?, do: "hero-speaker-x-mark", else: "hero-speaker-wave"}
              class="w-3.5 h-3.5 text-blue-500"
            />
            <span>{if @is_muted?, do: "Desmutar Chat", else: "Mutar Chat"}</span>
          </button>
        </li>
        <li>
          <button
            type="button"
            phx-click={
              JS.push("clear_chat_history", value: %{"chat-id" => @chat_id})
              |> JS.dispatch("click", to: "body")
            }
            class="flex items-center gap-2 py-1.5 px-2 hover:bg-gray-100 dark:hover:bg-gray-700/60 rounded-lg w-full text-left text-amber-600"
          >
            <.icon name="hero-trash" class="w-3.5 h-3.5" />
            <span>Limpar Conversa</span>
          </button>
        </li>
        <li>
          <button
            type="button"
            phx-click={
              JS.push("delete_chat_for_me", value: %{"chat-id" => @chat_id})
              |> JS.dispatch("click", to: "body")
            }
            class="flex items-center gap-2 py-1.5 px-2 hover:bg-gray-100 dark:hover:bg-gray-700/60 rounded-lg w-full text-left text-error"
          >
            <.icon name="hero-x-circle" class="w-3.5 h-3.5" />
            <span>Excluir Chat</span>
          </button>
        </li>
      </ul>
    </div>
    """
  end
end
