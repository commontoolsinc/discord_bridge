defmodule DiscordBridge.Schemas.MessageLog do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
    id: integer(),
    timestamp: DateTime.t(),
    user_id: String.t(),
    user_name: String.t(),
    channel_id: String.t(),
    content: String.t(),
    message_id: String.t(),
    guild_id: String.t() | nil,
    mentions: [String.t()],
    referenced_message_id: String.t() | nil,
    thread_id: String.t() | nil,
    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
  }

  schema "message_logs" do
    field(:timestamp, :utc_datetime)
    field(:user_id, :string)
    field(:user_name, :string)
    field(:channel_id, :string)
    field(:content, :string)
    field(:message_id, :string)
    field(:guild_id, :string)
    field(:mentions, {:array, :string}, default: [])
    field(:referenced_message_id, :string)
    field(:thread_id, :string)

    timestamps()
  end

  @required_fields [:timestamp, :user_id, :user_name, :channel_id, :content, :message_id]
  @optional_fields [:guild_id, :mentions, :referenced_message_id, :thread_id]

  def changeset(message_log, attrs) do
    message_log
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
