defmodule DiscordBridge.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      DiscordBridge.Repo,
      {Registry, keys: :unique, name: DiscordBridge.WorkerRegistry},
      DiscordBridge.ChannelSupervisor,
      DiscordBridge.Consumer,
      DiscordBridge.API.Server
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DiscordBridge.Supervisor]
    {:ok, supervisor_pid} = Supervisor.start_link(children, opts)

    # test getting channel history
    # DiscordBridge.ChannelSupervisor.start_channel_worker(1232452732963655720, 1232453747783761971)

    {:ok, supervisor_pid}
  end
end
