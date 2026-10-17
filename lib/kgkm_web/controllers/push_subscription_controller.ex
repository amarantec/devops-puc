defmodule KgkmWeb.PushSubscriptionController do
	use KgkmWeb, :controller
	alias Kgkm.Accounts
	
	def create(conn, %{"endpoint" => endpoint, "keys" => %{"p256dh" => p256dh, "auth" => auth}}) do
		user = conn.assigns[:current_scope] && conn.assigns[:current_scope].user
		
		if user do
			attrs = %{
				"endpoint" => endpoint,
				"p256dh" => p256dh,
				"auth" => auth
			}
			
			case Accounts.save_push_subscription(user.id, attrs) do
				{:ok, _sub} ->
					send_resp(conn, :created, "")
				{:error, _changeset} ->
					conn
					|> put_status(:unprocessable_entity)
					|> json(%{error: "Falha ao salvar subscrição"})
			end
		else
			send_resp(conn, :unauthorized, "")
		end
	end
end
				
