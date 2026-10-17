defmodule KgkmWeb.Router do
  use KgkmWeb, :router

  import KgkmWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {KgkmWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  # scope "/api", KgkmWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:kgkm, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: KgkmWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", KgkmWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{KgkmWeb.UserAuth, :require_authenticated}] do
      live "/", ChatLive.Index, :index
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/chats", ChatLive.Index, :index
      live "/chats/:id", ChatLive.Index, :show
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", KgkmWeb do
    pipe_through [:browser]

    # Se você quiser que a raiz para visitantes não logados vá para a página de login ou continue na home antiga:
    # Opção A: Mandar direto para o Login se não estiver logado
    # Ou você pode criar um Controller/LiveView de boas-vindas aqui
    get "/", PageController, :home

    live_session :current_user,
      on_mount: [{KgkmWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  # Adicione este scope para rotas de API com autenticação browser
  scope "/api", KgkmWeb do
    pipe_through [:browser, :require_authenticated_user]

    post "/push-subscriptions", PushSubscriptionController, :create
  end
end
