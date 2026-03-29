import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

config :auth, :jwt_secret, "test_secret"

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :auth, Auth.Repo,
  username: "postgres_auth",
  password: "password",
  hostname: "localhost",
  database: "auth_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2,
  port: 5433

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :auth, AuthWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "DvLZQs5LVDw51aAyi6K2Ead0Su975jyN+UiG67FbeIAkZSga0e6+ATAD4R1+BdmY",
  server: false

# In test we don't send emails
config :auth, Auth.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :auth, :google_oauth,
  client_id: "testtest.apps.googleusercontent.com",
  client_secret: "TEST-SECRET"

config :auth, :backend_url, "http://localhost:8080"

config :auth, :backend_authorization_token, "agsrgbbgadfaa"
