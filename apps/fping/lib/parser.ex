defmodule Fping.Parser do
  @moduledoc """

  Parser for fping output

  """

  @spec parse_fping_ips(binary) :: list
  def parse_fping_ips(output) do
    ips = output
    |> String.split("\n")
    |> Enum.flat_map(&IP.parse_ips/1)

    {:ok, ips}
  end
end
