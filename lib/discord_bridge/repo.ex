defmodule DiscordBridge.Repo do
  use Ecto.Repo,
    otp_app: :discord_bridge,
    adapter: Ecto.Adapters.SQLite3
end
