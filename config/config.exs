import Config

config :nostrum,
  token: System.fetch_env!("CT_BOT_TOKEN"),
  gateway_intents: :all

config :discord_bridge, DiscordBridge.Repo,
  database: "priv/discord_bridge.db",
  pool_size: 5

config :discord_bridge,
  ecto_repos: [DiscordBridge.Repo]
