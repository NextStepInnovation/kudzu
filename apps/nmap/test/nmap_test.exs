defmodule NmapTest do
  use ExUnit.Case
  doctest Nmap

  test "greets the world" do
    assert Nmap.hello() == :world
  end
end
