defmodule DiscordBridge.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DiscordBridge.Repo,
      DiscordBridge.Consumer,
      DiscordBridge.API.Server
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DiscordBridge.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
