import Config

config :nostrum,
  token: System.fetch_env!("CT_BOT_TOKEN"),
  gateway_intents: :all
