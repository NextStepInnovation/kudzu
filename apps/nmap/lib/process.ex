defmodule Nmap.Process do
  use GenServer, restart: :temporary, shutdown: 600

  require Logger

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @spec status(atom | pid | {atom, any} | {:via, atom, any}) :: any
  def status(process) do
    GenServer.call(process, :status)
  end

  @spec output_binary(maybe_improper_list) :: binary
  def output_binary(output) when is_list(output) do
    output
    |> Enum.reverse
    |> Enum.join("\n")
  end

  @spec output(pid) :: any
  def output(process) when is_pid(process) do
    GenServer.call(process, :output_binary)
  end

  def halt(process) do
    GenServer.stop(process, :shutdown)
  end

  @impl true
  def init(args) do
    {:ok, %{
        port: nil,
        port_info: nil,
        args: args,
        output: [],
        finished: false,
        success: nil,
        failure: nil,
     },
     {:continue, :start_nmap}}
  end

  def prepare_args(args) do
    with {:ok, arglist} <- args |> Args.from_list do
      {:ok, arglist ++ [{:oX, "-"}, {:stats_every, "2s"}]}
    end
  end

  @impl true
  def handle_continue(:start_nmap, state=%{args: args}) do
    with {:ok, arglist} <- prepare_args(args) do
      port = Port.open(
        {:spawn_executable, Nmap.exec_path},
        [:binary, :exit_status, args: arglist]
      )
      port_info = Port.info(port)
      state = state
      |> Map.put(:port, port)
      |> Map.put(:port_info, port_info)
      {:noreply, state}
    else
      {:error, error} ->
        {:stop, {:bad_args, error}, state}
    end
  end

  @impl true
  def handle_info({_port, {:exit_status, 0}}, %{output: output} = state) do
    Logger.info("nmap exited successfully...")
    case output
    |> output_binary
    |> Nmap.XmlParser.parse_nmap_binary do
      {:ok, nmap} ->
        Logger.info("  ... successful parse of nmap XML")
        {
          :noreply,
          state
          |> Map.put(:success, nmap)
          |> Map.put(:finished, true)
        }
      {:error, reason} ->
        Logger.error("  ... parse failed")
        {
          :noreply,
          state
          |> Map.put(:failure, {:bad_output, reason, output})
          |> Map.put(:finished, true)
        }
    end
  end

  @impl true
  def handle_info({_port, {:data, content}}, %{output: output} = state) do
    state = Map.put(state, :output, [content | output])
    {:noreply, state}
  end

  @impl true
  def handle_call(:output_binary, _from, %{output: output} = state) do
    {:reply, output_binary(output), state}
  end

  @impl true
  def handle_call(:status, _from, %{output: output, success: success,
                                    failure: failure} = state) do
    case {success, failure} do
      {nil, nil} ->
        status = output
        |> output_binary
        |> Nmap.XmlParser.parse_progress
        |> List.last

        {:reply, {:running, status}, state}

      {nmap, nil} ->
        {:reply, {:success, nmap}, state}

      {nil, error} ->
        {:reply, {:failure, error}, state}
    end
  end

  @impl true
  def terminate(_reason, %{finished: finished, port_info: port_info}) do
    Logger.info("Nmap terminated...")
    if not finished do
      {:ok, pid} = port_info[:os_pid] |> Utils.maybe_integer(0)
      Logger.info("Found running PID #{pid}. Killing...")
      if pid > 0 do
        case System.cmd("kill", ["-9", Integer.to_string(pid)]) do
          {success, 0} ->
            Logger.info("  ... PID #{pid} killed.")
            {:ok, success}
          {failure, code} ->
            Logger.error("  ... failure: #{code} #{failure}")
            {:error, code, failure}
        end
      end
    end
  end
end
