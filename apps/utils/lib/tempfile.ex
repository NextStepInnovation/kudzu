defmodule Tempfile do
  @moduledoc """
  Wrapper around briefly
  """

  require Logger
  def directory(opts \\ []) do
    Briefly.create(opts ++ [directory: true])
    # case System.cmd("mktemp", ["-d"]) do
    #   {output, 0} -> {:ok, output |> String.trim()}
    #   error -> {:error, error}
    # end
  end

  def file(opts \\ []) do
    opts = if Keyword.has_key?(opts, :suffix) do
      opts
      |> Keyword.put(:extname, opts[:suffix])
      |> Keyword.delete(:suffix)
    end
    
    Briefly.create(opts)
    # args = if suffix, do: ["--suffix", suffix], else: []

    # case System.cmd("mktemp", args, stderr_to_stdout: true) do
    #   {output, 0} -> {:ok, output |> String.trim()}
    #   error -> {:error, error}
    # end
  end
end
