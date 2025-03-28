defmodule DiscordBridge.ChannelWorker do
  @moduledoc """
  GenServer to fetch historical messages from a Discord channel.
  Each worker is uniquely identified by a {guild_id, channel_id} tuple.
  """
  alias DiscordBridge.Services.MessageService
  use GenServer
  require Logger

  # seconds interval for periodic checks
  @check_interval 3000

  # number of messages we should fetch at once
  @fetch_limit 100

  # how many messages do we want to fetch?
  @total_fetch 1000

  defstruct [:guild_id, :channel_id, :last_fetched_msgid, total_fetched: 0]

  # Client API

  @spec start_link({Nostrum.Struct.Guild.id(), Nostrum.Struct.Channel.id()}) ::
          GenServer.on_start()
  def start_link({guild_id, channel_id} = init_arg) do
    name = via_tuple(guild_id, channel_id)
    GenServer.start_link(__MODULE__, init_arg, name: name)
  end

  @spec via_tuple(Nostrum.Struct.Guild.id(), Nostrum.Struct.Channel.id()) ::
          {:via, Registry,
           {DiscordBridge.WorkerRegistry,
            {Nostrum.Struct.Guild.id(), Nostrum.Struct.Channel.id()}}}
  def via_tuple(guild_id, channel_id) do
    {:via, Registry, {DiscordBridge.WorkerRegistry, {guild_id, channel_id}}}
  end

  # Server Callbacks

  @impl true
  def init({guild_id, channel_id}) do
    Logger.info("Starting channel worker for guild=#{guild_id}, channel=#{channel_id}")

    # schedule regular checks
    schedule_check()

    {:ok,
     %__MODULE__{
       guild_id: guild_id,
       channel_id: channel_id,
       last_fetched_msgid: nil,
       total_fetched: 0
     }}
  end

  @impl true
  def handle_info(:check_channel, %__MODULE__{last_fetched_msgid: nil} = state) do
    # get the latest message in the channel
    {:ok, [%Nostrum.Struct.Message{id: msg_id, timestamp: msg_timestamp}]} =
      Nostrum.Api.Channel.messages(state.channel_id, 1)

    Logger.info(
      "channel_worker: got most recent message for channel #{inspect(state.channel_id)}, msg_id=#{inspect(msg_id)}, timestamp=#{inspect(msg_timestamp)}"
    )

    schedule_check()

    {:noreply, %{state | last_fetched_msgid: msg_id}}
  end

  def handle_info(:check_channel, %__MODULE__{total_fetched: total_fetched} = state)
      when total_fetched > @total_fetch do
    Logger.info(
      "fetched #{total_fetched} messages in total, channel_id=#{state.channel_id} ... ending"
    )

    {:stop, :shutdown, state}
  end

  def handle_info(:check_channel, %__MODULE__{} = state) do
    # the first message on the list will be the "newest" and the last will be the oldest message
    {message_list, status} =
      case Nostrum.Api.Channel.messages(
             state.channel_id,
             @fetch_limit,
             {:before, state.last_fetched_msgid}
           ) do
        {:ok, message_list} ->
          Logger.debug(
            "channel_worker: got message list, channel=#{state.channel_id}, len=#{length(message_list)}"
          )

          {message_list, :ok}

        {:error, reason} ->
          Logger.error("got error: #{inspect(reason)}")
          {[], :error}
      end

    # store these messages into the database
    Enum.each(message_list, fn msg ->
      case MessageService.log_message(msg) do
        {:ok, _} ->
          Logger.debug(
            "channel_worker: logged message - channelid=#{state.channel_id} msg_id=#{msg.id}"
          )

        {:error,
         %Ecto.Changeset{errors: [message_id: {_, [constraint: :unique, constraint_name: _]}]}} ->
          # Message already exists in the database, which is fine
          Logger.debug("message id #{msg.id} already exists in database")

        {:error, reason} ->
          Logger.error("failed logging message id #{msg.id}, reason=#{inspect(reason)}")
      end
    end)

    # update the last message fetch id
    last_msg_id =
      case message_list do
        [] ->
          state.last_fetched_msgid

        l ->
          Enum.map(l, fn elem -> elem.id end)
          |> List.last()
      end

    new_state = %{
      state
      | last_fetched_msgid: last_msg_id,
        total_fetched: state.total_fetched + length(message_list)
    }

    Logger.info(
      "channel_worker: fetched #{length(message_list)} messages for guild=#{new_state.guild_id}, channel=#{new_state.channel_id} (#{new_state.total_fetched} messages fetched so far)"
    )

    case {status, message_list} do
      {:ok, []} ->
        Logger.info("channel_worker: channel_id=#{new_state.channel_id} fetched all messages")
        {:stop, :shutdown, state}

      _ ->
        schedule_check()
        {:noreply, new_state}
    end
  end

  # Private functions

  defp schedule_check do
    Process.send_after(self(), :check_channel, @check_interval)
  end
end
