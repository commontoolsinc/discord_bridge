defmodule DiscordBridge.API.Server do
  @moduledoc """
  HTTP server for the Discord Bridge API
  """

  use Supervisor
  require Logger

  @default_port 8080

  @doc """
  Start the API server supervisor
  """
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Initialize the API server supervisor
  """
  @impl true
  def init(_opts) do
    port = get_port()
    Logger.info("Starting API server on port #{port}")

    children = [
      {Plug.Cowboy, scheme: :http, plug: DiscordBridge.API.Router, options: [port: port]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # Get the port from config or use default
  @spec get_port() :: integer()
  defp get_port do
    Application.get_env(:discord_bridge, :api_port, @default_port)
  end
end
