defmodule DiscordBridge.Consumer do
  use Nostrum.Consumer

  require Logger
  alias DiscordBridge.Services.MessageService

  # for debugging where the bot logs messages
  @logger_channel_id 1_318_255_745_376_190_518

  def handle_event({:READY, _ready_event, _ws_state}) do
    Logger.debug("#{__MODULE__}: got ready event")
    register_guild_commands()
  end

  def handle_event(
        {:MESSAGE_CREATE,
         %Nostrum.Struct.Message{
           author: %Nostrum.Struct.User{bot: nil} = author,
           channel_id: channel_id,
           content: content,
           id: msg_id,
           guild_id: _guild_id,
           mentions: _mentions,
           referenced_message: _ref_msg,
           timestamp: timestamp,
           thread: thread
         } = msg, _ws_state}
      ) do
    log_message =
      "new message: timestamp=#{timestamp}, user #{author.global_name}/#{author.id} wrote in channel <##{channel_id}>, content=#{content}, thread=#{inspect(thread)}"

    Logger.debug(log_message)
    Nostrum.Api.Message.create(@logger_channel_id, log_message)

    # Save the message to the database
    case MessageService.log_message(msg) do
      {:ok, _log} ->
        Logger.debug("Message #{msg_id} logged to database successfully")

      {:error, reason} ->
        Logger.error("Failed to log message #{msg_id} to database: #{inspect(reason)}")
    end

    :ok
  end

  @spec register_guild_commands() :: :ok
  def register_guild_commands() do
    start_command = %{
      name: "start",
      description: "Starts the bot"
    }

    {:ok, _ret_map} = Nostrum.Api.ApplicationCommand.create_global_command(start_command)
    :ok
  end
end
