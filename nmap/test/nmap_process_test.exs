defmodule NmapProcessTest do
  use ExUnit.Case
  doctest Nmap.Process

  test "are temporary workers" do
    assert Supervisor.child_spec(Nmap.Process, []).restart == :temporary
  end
end
