defmodule Fping.Command do
  use Shell.Command, command: "fping"

  def parse_ips(output) do
    ips =
      output
      |> output_binary
      |> String.split("\n")
      |> Enum.flat_map(&IP.parse_ips/1)

    {:ok, ips}
  end

  @impl true
  def handle_status(%{output: output, success: success, failure: failure}) do
    case {success, failure} do
      {nil, nil} -> {:running, output |> parse_ips}
      {s, nil} -> {:success, s}
      {nil, f} -> {:failure, f}
    end
  end

  @impl true
  def handle_exit(status, %{output: output}) when status in 0..2 do
    case output
         |> parse_ips do
      # {:error, reason} -> {:failure, {:bad_output, reason}}
      {:ok, ips} -> {:success, ips}
    end
  end

  @impl true
  def handle_exit(_status, %{output: output}) do
    {:failure, {:error_exit, output |> output_binary}}
  end
end
