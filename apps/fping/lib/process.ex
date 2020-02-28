defmodule Fping.Process do
  use GenServer, restart: :temporary, shutdown: 600

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def status(process) do
    GenServer.call(process, :status)
  end

  def output_binary(output) when is_list(output) do
    output
    |> Enum.reverse
    |> Enum.join("\n")
  end
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
      {:ok, arglist}
    end
  end

  @impl true
  def handle_continue(:start_nmap, state=%{args: args}) do
    with {:ok, arglist} <- prepare_args(args) do
      port = Port.open(
        {:spawn_executable, Fping.exec_path},
        [:binary, :exit_status, :stderr_to_stdout, args: arglist]
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

  def handle_output(status, %{output: output}) when status in 0..2 do
    case output
    |> output_binary
    |> Fping.Parser.parse_fping_ips do
      {:error, reason} -> {:error, {:bad_output, reason}}
      success -> success
    end
  end

  def handle_output(_status, %{output: output}) do
    {:error, {:error_exit, output |> output_binary}}
  end

  @impl true
  def handle_info({_port, {:exit_status, status}}, state) do
    state =
      case handle_output(status, state) do
        {:ok, success} -> state |> Map.put(:success, success)
        {:error, error} -> state |> Map.put(:failure, error)
      end
    {:noreply, state |> Map.put(:finished, true)}
  end  

  # @impl true
  # def handle_info({_port, {:exit_status, status}}, %{output: output} = state)
  #   when status in 0..2 do
  #   Logger.info("fping exited successfully...")
  #   case output
  #   |> output_binary
  #   |> Fping.Parser.parse_fping_ips do
  #     {:ok, ips} ->
  #       Logger.info("  ... successful parse of fping ips")
  #       {
  #         :noreply,
  #         state
  #         |> Map.put(:success, ips)
  #         |> Map.put(:finished, true)
  #       }
  #     {:error, reason} ->
  #       Logger.error("  ... parse failed")
  #       {
  #         :noreply,
  #         state
  #         |> Map.put(:failure, {:bad_output, reason, output})
  #         |> Map.put(:finished, true)
  #       }
  #   end
  # end
  
  # @impl true
  # def handle_info({_port, {:exit_status, status}}, %{output: output} = state) do
  #   Logger.error("fping exited unsuccessfully: code #{status}...")
  #   error = output
  #   |> output_binary

  #   Logger.error(error)

  #   {
  #     :noreply,
  #     state
  #     |> Map.put(:finished, true)
  #     |> Map.put(:failure, {:error_exit, error})
  #   }
  # end
  
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

        {:reply, {:running, status}, state}

      {nmap, nil} ->
        {:reply, {:success, nmap}, state}

      {nil, error} ->
        {:reply, {:failure, error}, state}
    end
  end

  @impl true
  def terminate(_reason, %{finished: finished, port_info: port_info}) do
    Logger.info("Fping terminated...")
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
