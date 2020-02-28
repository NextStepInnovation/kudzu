defmodule FpingTest do
  use ExUnit.Case
  doctest Fping

  test "greets the world" do
    assert Fping.hello() == :world
  end
end
