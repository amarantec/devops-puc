import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.

db_username =
  System.get_env("POSTGRES_USER") || raise "POSTGRES_USER environment variable n
ot set."

db_password =
  System.get_env("POSTGRES_PASSWORD") || raise "POSTGRES_PASSWORD environment va
riable not set."

db_host =
  System.get_env("DB_HOST") || raise "DB_HOST environment variable not set."

db_name =
  System.get_env("POSTGRES_DB") || raise "POSTGRES_DB environment variable not s
et."

secret_key_base =
  System.get_env("SECRET_KEY_BASE") || raise "SECRET_KEY_BASE environment variab
le not set."

config :kgkm, Kgkm.Repo,
  username: db_username,
  password: db_password,
  hostname: db_host,
  database: "kgkm_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :kgkm, KgkmWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: secret_key_base,
  server: false

# In test we don't send emails
config :kgkm, Kgkm.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
