defmodule Nmap.Process do
  use GenServer, restart: :temporary

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def nmap_exec_path do
    System.find_executable("nmap")
  end

  # def child_spec(args) do
  #   %{id: Nmap.Process, start: {Nmap.Process, :start_link, [args]}}
  # end

  def status(process) do
    GenServer.call(process, :status)
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

  @impl true
  def handle_continue(:start_nmap, state=%{args: args}) do
    args = args ++ [{:oX, "-"}, {:stats_every, "2s"}]
    with {:ok, arglist} <- args |> Nmap.Args.from_list do
      IO.inspect([nmap_exec_path() | arglist])
      port = Port.open(
        {:spawn_executable, nmap_exec_path()},
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
    |> Enum.reverse
    |> Enum.join("\n")
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
  def handle_call(
    :status, _from, %{output: output, success: success,
                      failure: failure} = state) do
    case {success, failure} do
      {nil, nil} ->
        outstr = output |> Enum.reverse |> Enum.join("\n")

        status = outstr
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
    if not finished do
      {:ok, pid} = port_info[:os_pid] |> Utils.maybe_integer(0)
      Logger.warn("Found running PID #{pid}. Killing...")
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
