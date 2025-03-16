# DiscordBridge

This bot can take messages from Discord and serve them to a [charm](https://github.com/commontoolsinc/labs).
Still work in progress.

## Installation

Create a Discord Bot on [Discord's Developer website](https://discord.com/developers/applications).
Under the Bot section, generate your bot's token and store it in an environment variable called "CT_BOT_TOKEN".
Also under the Bot section, turn on all "Priviledged Gateway Intents", this will allow the bot to read messages on the server, among other things.

## Nix
While Nix isn't required, there is a `shell.nix` that should have what's needed for development. Just run `nix-shell` to set up your environment.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/discord_bridge>.

## Running the bot
* mix deps.get # gets the dependencies
* mix deps.compile # compiles dependencies
* mix compile

## Setting up the database
* mix ecto.create # do this only once
* mix ecto.migrate # anytime the db changes

## Running the bot under repl
* iex -S mix # runs the bot under the repl

## Inviting the bot that Ellyse is running
Click this [Bot invite link](https://discord.com/oauth2/authorize?client_id=1343617049385242697&permissions=2182089728&integration_type=0&scope=bot)
then select the Discord server you are managing.
It may not be running all the time at the moment until we decide it's "working" and that we want to run this.

## REST API

The bot includes a REST API that allows you to retrieve messages stored in the database. The API runs on port 8080 by default. You can edit config/config.exs to modify this port.

### API Endpoints

#### GET /api/messages

Returns messages from the database, optionally filtered by a timestamp.

**Query Parameters:**
- `since` (optional): ISO8601 timestamp (e.g., "2025-03-16T00:00:00Z"). If provided, only returns messages after this timestamp. All times are UTC.

**Example Requests:**

```bash
# Get all messages
curl "http://localhost:4000/api/messages"

# Get messages since a specific date
curl "http://localhost:4000/api/messages?since=2025-03-16T12:00:00Z"
```
