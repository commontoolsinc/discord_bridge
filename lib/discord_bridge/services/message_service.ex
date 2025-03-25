defmodule DiscordBridge.Services.MessageService do
  alias DiscordBridge.Repo
  alias DiscordBridge.Schemas.MessageLog
  require Logger

  @doc """
  Logs a message to the database
  """
  @spec log_message(Nostrum.Struct.Message.t()) :: {:ok, MessageLog.t()} | {:error, term()}
  def log_message(%Nostrum.Struct.Message{} = msg) do
    %{
      author: %Nostrum.Struct.User{} = author,
      channel_id: channel_id,
      content: content,
      id: msg_id,
      guild_id: guild_id,
      mentions: mentions,
      referenced_message: referenced_message,
      timestamp: %DateTime{} = timestamp,
      thread: thread
    } = msg

    # Extract mention IDs
    mention_ids = Enum.map(mentions, fn user -> to_string(user.id) end)

    # Extract referenced message ID if present
    ref_msg_id = if referenced_message, do: to_string(referenced_message.id), else: nil

    # Extract thread ID if present
    thread_id = if thread, do: to_string(thread.id), else: nil

    attrs = %{
      timestamp: timestamp,
      user_id: to_string(author.id),
      user_name: author.global_name || author.username || "Unknown User",
      channel_id: to_string(channel_id),
      content: content,
      message_id: to_string(msg_id),
      guild_id: if(guild_id, do: to_string(guild_id), else: nil),
      mentions: mention_ids,
      referenced_message_id: ref_msg_id,
      thread_id: thread_id
    }

    %MessageLog{}
    |> MessageLog.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, log} ->
        {:ok, log}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Retrieves messages from a specific channel
  """
  @spec get_messages_by_channel(Nostrum.Struct.Channel.id(), integer()) :: [MessageLog.t()]
  def get_messages_by_channel(channel_id, limit \\ 100) when is_integer(channel_id) do
    import Ecto.Query

    channel_id_str = to_string(channel_id)

    MessageLog
    |> where([m], m.channel_id == ^channel_id_str)
    |> order_by([m], desc: m.timestamp)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Retrieves messages from a specific user
  """
  @spec get_messages_by_user(Nostrum.Struct.User.id(), integer()) :: [MessageLog.t()]
  def get_messages_by_user(user_id, limit \\ 100) when is_integer(user_id) do
    import Ecto.Query

    user_id_str = to_string(user_id)

    MessageLog
    |> where([m], m.user_id == ^user_id_str)
    |> order_by([m], desc: m.timestamp)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Retrieves messages since a specific timestamp
  """
  @spec get_messages_since(DateTime.t(), integer()) :: [MessageLog.t()]
  def get_messages_since(timestamp, limit \\ 100) do
    import Ecto.Query

    MessageLog
    |> where([m], m.timestamp >= ^timestamp)
    |> order_by([m], asc: m.timestamp)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Retrieves messages from a specific channel since a timestamp
  """
  @spec get_channel_messages_since(Nostrum.Struct.Channel.id(), DateTime.t(), integer()) :: [
          MessageLog.t()
        ]
  def get_channel_messages_since(channel_id, timestamp, limit \\ 100)
      when is_integer(channel_id) do
    import Ecto.Query

    # Convert channel_id to string if it's a snowflake
    channel_id_str = to_string(channel_id)

    MessageLog
    |> where([m], m.channel_id == ^channel_id_str and m.timestamp >= ^timestamp)
    |> order_by([m], asc: m.timestamp)
    |> limit(^limit)
    |> Repo.all()
  end
end
