defmodule Tempfile do
  @moduledoc """
  Wrapper around mktemp
  """

  def directory() do
    case System.cmd("mktemp", ["-d"]) do
      {output, 0} -> {:ok, output |> String.trim()}
      error -> {:error, error}
    end
  end

  def file(suffix \\ nil) do
    args = if suffix, do: ["--suffix", suffix], else: []

    case System.cmd("mktemp", args, stderr_to_stdout: true) do
      {output, 0} -> {:ok, output |> String.trim()}
      error -> {:error, error}
    end
  end
end
