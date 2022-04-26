defmodule Fping do
  @moduledoc """

  Wrapper functionality for `fping` command.

  """

  require Logger

  def exec_path do
    Application.fetch_env!(:fping, :exec_path)
  end

  @spec scan_subnet(binary) :: {:ok, {{:fping, term}, list}} | {:error, term}
  def scan_subnet(subnet) when is_binary(subnet) do
    args = [:aq, :g, subnet]
    key = {:fping, args}

    case Shell.Server.start(Fping.Command, key, args) do
      :ok -> {:ok, {key, args}}
      error -> {:error, error}
    end
  end

  defp check_scan(key) do
    case Shell.Server.status(key) do
      {:running, _} ->
        Logger.info("not done...")
        :timer.sleep(1000)
        check_scan(key)

      outcome ->
        IO.inspect(outcome)
    end
  end

  @spec scan_subnet!(binary) :: binary
  def scan_subnet!(subnet) when is_binary(subnet) do
    with {:ok, {key, _}} <- scan_subnet(subnet),
         {:success, ips} <- Shell.Server.outcome(key) do
      ips
    else
      error ->
        raise error
    end
  end
end
