defmodule Nmap do
  @moduledoc """
  nmap network scanner tools
  """

  def base, do: "/usr/share/nmap/"
  def scripts, do: Path.join(Nmap.base, "scripts")

  def script_glob(glob) do
    Path.join(Nmap.scripts, glob)
    |> Path.wildcard
  end
end
