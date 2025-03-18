defmodule DiscordBridge.ChannelSupervisor do
  @moduledoc """
  Dynamic supervisor for channel workers.
  Each worker is responsible for a specific Discord guild and channel.
  """
  use DynamicSupervisor
  require Logger

  @spec start_link(any) :: Supervisor.on_start()
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a channel worker for the given guild and channel ID.
  """
  @spec start_channel_worker(Nostrum.Struct.Guild.id(), Nostrum.Struct.Channel.id()) ::
          DynamicSupervisor.on_start_child()
  def start_channel_worker(guild_id, channel_id) do
    child_spec = %{
      id: DiscordBridge.ChannelWorker,
      start: {DiscordBridge.ChannelWorker, :start_link, [{guild_id, channel_id}]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Returns a list of all running channel workers.
  """
  @spec list_workers() :: [{Nostrum.Struct.Guild.id(), Nostrum.Struct.Channel.id(), pid}]
  def list_workers do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} ->
      case Registry.keys(DiscordBridge.WorkerRegistry, pid) do
        [{guild_id, channel_id}] -> {guild_id, channel_id, pid}
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end
end
