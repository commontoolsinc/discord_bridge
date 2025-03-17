defmodule DiscordBridge.Schemas.LastMessageTime do
  use Ecto.Schema
  import Ecto.Changeset

  @type requestor_id :: String.t()

  @type t :: %__MODULE__{
          id: integer(),
          requestor_id: requestor_id(),
          last_message_timestamp: DateTime.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "last_message_times" do
    field(:requestor_id, :string)
    field(:last_message_timestamp, :utc_datetime)

    timestamps()
  end

  @required_fields [:requestor_id, :last_message_timestamp]

  def changeset(last_message_time, attrs) do
    last_message_time
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:requestor_id)
  end
end
