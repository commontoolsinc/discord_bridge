defmodule DiscordBridge.API.MessageController do
  import Plug.Conn
  require Logger
  alias DiscordBridge.Services.MessageService
  alias DiscordBridge.Schemas.MessageLog
  alias Plug.Conn

  @type timestamp_result :: {:ok, DateTime.t()} | :all | {:error, atom() | String.t()}

  @doc """
  Handler for GET /api/messages
  Optional query parameter: since (ISO8601 timestamp)
  Returns all messages since the provided timestamp, or all messages if no timestamp provided
  """
  @spec get_messages(Conn.t()) :: Conn.t()
  def get_messages(%Conn{params: params} = conn) do
    since_param = params["since"]

    case parse_timestamp(since_param) do
      {:ok, %DateTime{} = timestamp} ->
        messages = MessageService.get_messages_since(timestamp)
        send_json_response(conn, 200, format_messages(messages))

      :all ->
        # If no valid timestamp provided, return all messages using a very old date
        messages = MessageService.get_messages_since(DateTime.from_unix!(0))
        send_json_response(conn, 200, format_messages(messages))

      {:error, reason} ->
        send_json_response(conn, 400, %{error: "Invalid timestamp format: #{reason}"})
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
        id: message.id,
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
end