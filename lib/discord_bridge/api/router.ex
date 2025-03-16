defmodule DiscordBridge.API.Router do
  use Plug.Router
  require Logger

  plug(Plug.Logger)
  plug(DiscordBridge.API.CORSPlug)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  alias DiscordBridge.API.MessageController

  # API endpoints
  get "/api/messages" do
    MessageController.get_messages(conn)
  end
  
  # Handle OPTIONS requests for CORS preflight
  options "/api/messages" do
    conn
    |> put_resp_header("access-control-max-age", "86400")
    |> send_resp(204, "")
  end

  # Fallback for all other routes
  match _ do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(404, Jason.encode!(%{error: "Not found"}))
  end
end
