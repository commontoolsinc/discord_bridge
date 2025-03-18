defmodule DiscordBridge.Services.LastMessageTimeService do
  @moduledoc """
  Service for tracking the last message timestamp for each requestor
  """

  alias DiscordBridge.Repo
  alias DiscordBridge.Schemas.LastMessageTime
  alias DiscordBridge.Schemas.MessageLog
  import Ecto.Query
  require Logger

  @type requestor_id :: LastMessageTime.requestor_id()

  @doc """
  Gets the last message timestamp for a requestor.
  If no record exists, returns the Unix epoch (1970-01-01).
  """
  @spec get_last_message_time(requestor_id()) :: DateTime.t()
  def get_last_message_time(requestor_id) when is_binary(requestor_id) do
    case Repo.get_by(LastMessageTime, requestor_id: requestor_id) do
      %LastMessageTime{last_message_timestamp: timestamp} ->
        timestamp

      nil ->
        # If no record exists, return Unix epoch
        DateTime.from_unix!(0)
    end
  end

  @doc """
  Updates the last message timestamp for a requestor.
  Creates a new record if one doesn't exist.
  """
  @spec update_last_message_time(requestor_id(), DateTime.t()) ::
          {:ok, LastMessageTime.t()} | {:error, Ecto.Changeset.t()}
  def update_last_message_time(requestor_id, %DateTime{} = timestamp)
      when is_binary(requestor_id) do
    case Repo.get_by(LastMessageTime, requestor_id: requestor_id) do
      %LastMessageTime{} = record ->
        # Update existing record
        record
        |> LastMessageTime.changeset(%{last_message_timestamp: timestamp})
        |> Repo.update()

      nil ->
        # Create new record
        %LastMessageTime{}
        |> LastMessageTime.changeset(%{
          requestor_id: requestor_id,
          last_message_timestamp: timestamp
        })
        |> Repo.insert()
    end
  end

  @doc """
  Gets messages since the last message timestamp for a requestor.
  Also updates the last message timestamp to the latest message timestamp.

  Returns {:ok, messages} if successful, or {:error, reason} if updating the timestamp fails.
  """
  @spec get_messages_since_last(requestor_id()) ::
          {:ok, [MessageLog.t()]} | {:error, Ecto.Changeset.t()}
  def get_messages_since_last(requestor_id) when is_binary(requestor_id) do
    # Get the last message timestamp
    last_timestamp = get_last_message_time(requestor_id)

    # Get messages since that timestamp
    messages =
      MessageLog
      |> where([m], m.timestamp > ^last_timestamp)
      |> order_by([m], asc: m.timestamp)
      |> Repo.all()

    # If there are messages, update the last message timestamp
    case messages do
      [] ->
        # No new messages
        {:ok, messages}

      messages ->
        # Get the latest message timestamp
        latest_timestamp = List.last(messages).timestamp

        # Update the last message timestamp and propagate any errors
        case update_last_message_time(requestor_id, latest_timestamp) do
          {:ok, _record} ->
            Logger.debug(
              "Updated last message timestamp for requestor #{requestor_id} to #{latest_timestamp}"
            )

            {:ok, messages}

          {:error, _changeset} = error ->
            Logger.error("Failed to update last message timestamp for requestor #{requestor_id}")
            error
        end
    end
  end
end
