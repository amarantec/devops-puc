defmodule Kgkm.Repo do
  use Ecto.Repo,
    otp_app: :kgkm,
    adapter: Ecto.Adapters.Postgres
end
