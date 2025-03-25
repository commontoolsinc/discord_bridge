defmodule DiscordBridge.API.MessageController do
  import Plug.Conn
  require Logger
  alias DiscordBridge.Services.MessageService
  alias DiscordBridge.Services.LastMessageTimeService
  alias DiscordBridge.Schemas.MessageLog
  alias DiscordBridge.Schemas.LastMessageTime
  alias Plug.Conn

  @type timestamp_result :: {:ok, DateTime.t()} | :all | {:error, atom() | String.t()}
  @type requestor_id :: LastMessageTime.requestor_id()

  @default_max_historical_messages 1000

  @doc """
  Handler for GET /api/messages
  Required query parameter: requestor_id - Identifier for the client requesting messages
  Optional query parameter: since (ISO8601 timestamp) - Only return messages after this time

  If since is not provided, returns messages since the last request for this requestor_id
  """
  @spec get_messages(Conn.t()) :: Conn.t()
  def get_messages(%Conn{params: params} = conn) do
    requestor_id = params["requestor_id"]
    since_param = params["since"]

    if is_nil(requestor_id) or requestor_id == "" do
      send_json_response(conn, 400, %{error: "Missing required parameter: requestor_id"})
    else
      case parse_timestamp(since_param) do
        {:ok, %DateTime{} = timestamp} ->
          # When timestamp is provided, get messages since that time
          messages = MessageService.get_messages_since(timestamp)

          # Update the last message time for this requestor if there are messages
          if messages != [] do
            latest_timestamp =
              messages
              |> Enum.map(& &1.timestamp)
              |> Enum.max(DateTime)

            # Update but don't crash if update fails
            {:ok, _last_msg} =
              LastMessageTimeService.update_last_message_time(requestor_id, latest_timestamp)

            Logger.debug(
              "MessageController.get_messages: got #{length(messages)} new messages since #{inspect(timestamp)}"
            )
          else
            Logger.debug(
              "MessageController.get_messages: no new messages since #{inspect(timestamp)}"
            )
          end

          send_json_response(conn, 200, format_messages(messages))

        :all ->
          # If no valid timestamp provided, get messages since last request for this requestor
          case LastMessageTimeService.get_messages_since_last(requestor_id) do
            {:ok, messages} ->
              Logger.debug(
                "MessageController.get_messages: no since passed, got #{length(messages)} new messages"
              )

              max_num_msgs = get_max_historical_messages()
              limited_messages = Enum.take(messages, -1 * max_num_msgs)
              send_json_response(conn, 200, format_messages(limited_messages))

            {:error, reason} ->
              Logger.debug(
                "MessageController.get_messages: no since passed, error getting messages: #{inspect(reason)}"
              )

              send_json_response(conn, 500, %{
                error: "Failed to update last message time: #{inspect(reason)}"
              })
          end

        {:error, reason} ->
          send_json_response(conn, 400, %{error: "Invalid timestamp format: #{reason}"})
      end
    end
  end

  # Parse timestamp from string to DateTime
  @spec parse_timestamp(String.t() | nil) :: timestamp_result
  defp parse_timestamp(nil), do: :all
  defp parse_timestamp(""), do: :all

  defp parse_timestamp(timestamp_str) when is_binary(timestamp_str) do
    case DateTime.from_iso8601(timestamp_str) do
      {:ok, %DateTime{} = datetime, _offset} -> {:ok, datetime}
      {:error, reason} -> {:error, reason}
    end
  end

  # Format messages for JSON response
  @spec format_messages([MessageLog.t()]) :: [map()]
  defp format_messages(messages) when is_list(messages) do
    Enum.map(messages, fn %MessageLog{} = message ->
      %{
        # Use message_id as id for backward compatibility
        id: message.message_id,
        timestamp: message.timestamp,
        user_id: message.user_id,
        user_name: message.user_name,
        channel_id: message.channel_id,
        content: message.content,
        message_id: message.message_id,
        guild_id: message.guild_id,
        mentions: message.mentions,
        referenced_message_id: message.referenced_message_id,
        thread_id: message.thread_id
      }
    end)
  end

  # Helper to send JSON responses
  @spec send_json_response(Conn.t(), integer(), map() | list()) :: Conn.t()
  defp send_json_response(%Conn{} = conn, status, data) when is_integer(status) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  # Get the port from config or use default
  @spec get_max_historical_messages() :: integer()
  defp get_max_historical_messages do
    Application.get_env(
      :discord_bridge,
      :max_historical_messages,
      @default_max_historical_messages
    )
  end
end
