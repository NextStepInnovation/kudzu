defmodule DirbTest do
  use ExUnit.Case
  doctest Dirb

  test "greets the world" do
    assert Dirb.hello() == :world
  end
end
