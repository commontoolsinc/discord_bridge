defmodule DiscordBridge.Consumer do
  use Nostrum.Consumer

  require Logger

  def handle_event({:READY, _ready_event, _ws_state}) do
    Logger.debug("#{__MODULE__}: got ready event")
    register_guild_commands()
  end

  @spec register_guild_commands() :: :ok
  def register_guild_commands() do
    start_command = %{
      name: "start",
      description: "Starts the bot",
    }
    {:ok, _ret_map} = Nostrum.Api.ApplicationCommand.create_global_command(start_command)
    :ok
  end
end
