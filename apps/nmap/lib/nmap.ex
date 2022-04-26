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
    Path.join(Nmap.nse_scripts_path(), glob)
    |> Path.wildcard()
  end

  def scan_ip(ip) when is_binary(ip) do
    args = [ip]
    key = {:nmap, args}

    case Shell.Server.start(Nmap.Command, key, args) do
      :ok -> {:ok, {key, args}}
      # error -> {:error, error}
    end
  end

  @spec scan_ip!(binary) :: map
  def scan_ip!(ip) when is_binary(ip) do
    with {:ok, {key, _}} <- scan_ip(ip),
         {:success, nmap} <- Shell.Server.outcome(key) do
      nmap
    else
      error ->
        raise error
    end
  end

  @spec scan_ips(maybe_improper_list) :: list
  def scan_ips(ips) when is_list(ips) do
    ips
    |> Enum.map(&scan_ip/1)
  end
  def scan_ips(_bad) do
    {:error, :not_a_list}
  end

  @spec scan_ips!(list) :: list
  def scan_ips!(ips) when is_list(ips) do
    ips
    |> Enum.map(&scan_ip!/1)
  end
end
