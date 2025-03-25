defmodule DiscordBridge.Schemas.MessageLog do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          message_id: String.t(),
          timestamp: DateTime.t(),
          user_id: String.t(),
          user_name: String.t(),
          channel_id: String.t(),
          content: String.t() | nil,
          guild_id: String.t() | nil,
          mentions: [String.t()],
          referenced_message_id: String.t() | nil,
          thread_id: String.t() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @primary_key {:message_id, :string, []}
  schema "message_logs" do
    field(:timestamp, :utc_datetime)
    field(:user_id, :string)
    field(:user_name, :string)
    field(:channel_id, :string)
    field(:content, :string)
    field(:guild_id, :string)
    field(:mentions, {:array, :string}, default: [])
    field(:referenced_message_id, :string)
    field(:thread_id, :string)

    timestamps()
  end

  @required_fields [:timestamp, :user_id, :user_name, :channel_id, :message_id]
  @optional_fields [:content, :guild_id, :mentions, :referenced_message_id, :thread_id]

  def changeset(message_log, attrs) do
    message_log
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:message_id, name: "message_logs_message_id_index")
  end
end
