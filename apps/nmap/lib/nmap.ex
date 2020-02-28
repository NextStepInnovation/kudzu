defmodule Nmap do
  @moduledoc """
  nmap network scanner tools
  """

  def exec_path do
    Application.fetch_env!(:nmap, :exec_path)
  end

  def nse_scripts_path do
    Application.fetch_env!(:nmap, :nse_scripts_path)
  end

  def script_glob(glob) do
    Path.join(Nmap.nse_scripts_path, glob)
    |> Path.wildcard
  end

end
