defmodule Nmap.Command do
  use Shell.Command, command: "nmap"
  require Logger

  @impl true
  def command_init(state) do
    with {:ok, norm_path} <- Tempfile.file(".txt"),
         {:ok, xml_path} <- Tempfile.file(".xml") do
      {:ok,
       state
       |> Map.put(:nmap, %{xml_path: xml_path, norm_path: norm_path})}
    end
  end

  @impl true
  def command_args(%{args: args, nmap: %{norm_path: norm_path}}) do
    (args ++ [{:oX, "-"}, {:oN, norm_path}, {:stats_every, "2s"}])
    |> Args.from_list()
  end

  @impl true
  def handle_status(%{output: output, success: success, failure: failure}) do
    case {success, failure} do
      {nil, nil} ->
        status =
          output
          |> output_binary
          |> Nmap.XmlParser.parse_progress()
          |> List.last()

        {:running, status}

      {nmap, nil} ->
        {:success, nmap}

      {nil, error} ->
        {:failure, error}
    end
  end

  @impl true
  def handle_exit(0, %{nmap: %{xml_path: xml_path, norm_path: norm_path}, output: output}) do
    Logger.info("Nmap exited successfully...")

    xml_content = output |> output_binary

    case xml_content |> Nmap.XmlParser.parse_nmap_binary() do
      {:ok, nmap} ->
        Logger.info("  ... successful parse of nmap XML")
        Logger.info("  ... normal output at #{norm_path}")

        case File.write(xml_path, xml_content) do
          :ok ->
            Logger.info("  ... successfully written XML to #{xml_path}")

          {:error, reason} ->
            Logger.error("  ... failure to write XML to #{xml_path} for reason: #{reason}")
        end

        {:success, nmap}

      {:error, reason} ->
        Logger.error("  ... parse failed")
        {:failure, {:bad_output, reason}}
    end
  end

  @impl true
  def handle_exit(_status, %{output: output}) do
    {:failure, {:error_exit, output |> output_binary}}
  end
end
