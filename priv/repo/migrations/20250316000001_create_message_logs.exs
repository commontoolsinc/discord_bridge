defmodule DiscordBridge.Repo.Migrations.CreateMessageLogs do
  use Ecto.Migration

  def change do
    create table(:message_logs, primary_key: false) do
      add :message_id, :string, primary_key: true
      add :timestamp, :utc_datetime, null: false
      add :user_id, :string, null: false
      add :user_name, :string, null: false
      add :channel_id, :string, null: false
      add :content, :text, null: false
      add :guild_id, :string
      add :mentions, :text # We'll store as JSON
      add :referenced_message_id, :string
      add :thread_id, :string
      
      timestamps()
    end

    create index(:message_logs, [:channel_id])
    create index(:message_logs, [:user_id])
  end
end