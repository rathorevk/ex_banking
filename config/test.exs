import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ex_banking, ExBankingWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "TKTXg1V7DN6xmrPVRCUbk4WWHPIirOqTxW/tTmTCXuM1AhKQuMabchtusjBTIBvm",
  server: false

# Print only warnings and errors during test
config :logger, level: :error
