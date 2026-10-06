defmodule KgkmWeb.PageController do
  use KgkmWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
