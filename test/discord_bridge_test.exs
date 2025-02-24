defmodule DiscordBridgeTest do
  use ExUnit.Case
  doctest DiscordBridge

  test "greets the world" do
    assert DiscordBridge.hello() == :world
  end
end
