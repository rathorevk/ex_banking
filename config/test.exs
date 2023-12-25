import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ex_banking, ExBankingWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "TKTXg1V7DN6xmrPVRCUbk4WWHPIirOqTxW/tTmTCXuM1AhKQuMabchtusjBTIBvm",
  server: false

# In test we don't send emails.
config :ex_banking, ExBanking.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Configure RateLimiter
config :ex_banking, :rate_limit,
  # Size of the rate limiting window in milliseconds.
  window_size_ms: 5 * 1000,
  # Rate limit — i.e. the maximum number of requests allowed for the window.
  maximum_request_count: 10,
  # Interval in the milliseconds for removing outdated data from the usage table.
  cleanup_interval_ms: 120 * 1000
