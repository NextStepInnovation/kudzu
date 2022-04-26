defmodule ImpacketTest do
  use ExUnit.Case
  doctest Impacket

  test "greets the world" do
    assert Impacket.hello() == :world
  end
end
