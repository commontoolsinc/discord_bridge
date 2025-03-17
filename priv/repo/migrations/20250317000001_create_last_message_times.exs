defmodule DiscordBridge.Repo.Migrations.CreateLastMessageTimes do
  use Ecto.Migration

  def change do
    create table(:last_message_times) do
      add :requestor_id, :string, null: false
      add :last_message_timestamp, :utc_datetime, null: false
      
      timestamps()
    end

    create unique_index(:last_message_times, [:requestor_id])
  end
end