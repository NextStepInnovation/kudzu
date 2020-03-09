defmodule Nikto.Command do
  use Shell.Command, command: "nikto"

  @impl true
  def command_init(state) do
    with {:ok, csv_path} <- Tempfile.file(suffix: ".csv") do
      {:ok, state |> Map.put(:nikto, %{csv_path: csv_path})}
    end
  end

  @impl true
  def command_args(%{args: args, nikto: %{csv_path: csv_path}}) do
    (args ++ [{"-ask", "no"}, {"-F", "csv"}, {"-o", csv_path}])
    |> Args.from_list()
  end

  def parse_output(output) do
    output
  end

  @impl true
  def handle_status(%{output: output, success: success, failure: failure}) do
    case {success, failure} do
      {nil, nil} -> {:running, output |> parse_output}
      {s, nil} -> {:success, s}
      {nil, f} -> {:failure, f}
    end
  end

  defp parse_csv(path) do
    if File.exists?(path) do
      {:ok,
       File.stream!(path)
       |> CSV.decode(headers: ["hostname", "ip", "port", "osvdb", "method", "path", "message"])
       |> Enum.filter(fn {atom, _} -> atom == :ok end)
       |> Enum.map(fn {_, row} -> row end)}
    else
      {:error, {:no_csv_path, %{csv_path: path}}}
    end
  end

  @impl true
  def handle_exit(0, %{nikto: %{csv_path: csv_path}, output: _output}) do
    case csv_path |> parse_csv do
      {:error, reason} -> {:failure, {:bad_output, reason}}
      {:ok, rows} -> {:success, rows}
    end
  end

  @impl true
  def handle_exit(_status, %{output: output}) do
    {:failure, {:error_exit, output |> output_binary}}
  end
end
