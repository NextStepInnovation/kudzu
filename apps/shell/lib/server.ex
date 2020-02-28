defmodule Shell.Server do
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  # ------------------------------------------------------------
  # Client API
  # ------------------------------------------------------------
  def fetch(name) do
    GenServer.call(__MODULE__, {:fetch, name})
  end

  def status(name) do
    GenServer.call(__MODULE__, {:status, name})
  end
  def status() do
    GenServer.call(__MODULE__, :status)
  end

  def start(module, name, args) do
    GenServer.cast(__MODULE__, {:start, module, name, args}) 
  end

  def halt(name) do
    GenServer.call(__MODULE__, {:halt, name})
  end

  def flush() do
    GenServer.call(__MODULE__, :flush)
  end

  # ------------------------------------------------------------
  # Server API
  # ------------------------------------------------------------

  @impl true
  def init(:ok) do
    processes = %{}
    monitors = %{}
    {:ok, {processes, monitors}}
  end

  @impl true
  def handle_call(:flush, _from, {processes, _} = state) do
    finished = processes
    |> Enum.filter(
      fn({_, pid}) ->
        case Shell.Command.status(pid) do
          {:success, _} -> true
          {:failure, _} -> true
          _ -> false
        end
      end
    )
    |> Enum.map(fn({_, pid}) -> Shell.Command.halt(pid) end)
    
    {:reply, {:ok, finished}, state}
  end

  @impl true
  def handle_call({:fetch, name}, _from, {processes, _} = state) do
    {:reply, Map.fetch(processes, name), state}
  end

  @impl true
  def handle_call({:status, name}, _from, {processes, _} = state) do
    case Map.fetch(processes, name) do
      {:ok, pid} -> {:reply, Shell.Command.status(pid), state}
      _ -> {:reply, :error, state}
    end
  end

  @impl true
  def handle_call(:status, _from, {processes, _} = state) do
    status = processes
    |> Enum.map(
      fn({name, pid}) ->
        case Shell.Command.status(pid) do
          {:running, nil} -> {name, "Starting..."}
          {:running, %{task: task, percent: percent,
                        remaining: remaining}} ->
              {name, "#{task}: #{remaining}s (#{percent}%)"}
          {:success, _} -> {name, "Done."}
          {:failure, _} -> {name, "FAILED."}
        end
      end
    )
    |> Enum.into(%{})
    {:reply, status, state}
  end

  @impl true
  def handle_call({:halt, name}, _from, {processes, _} = state) do
    pid = Map.get(processes, name)
    case Shell.Command.halt(pid) do
      :ok -> {:reply, :ok, state}
      error -> {:reply, error, state}
    end
  end
  
  @impl true
  def handle_cast({:start, module, name, args}, {processes, monitors}) do
    if Map.has_key?(processes, name) do
      {:noreply, {processes, monitors}}
    else
      # IO.inspect(args)
      {:ok, pid} = DynamicSupervisor.start_child(
        Shell.CommandSupervisor, {module, args}
      )
      ref = Process.monitor(pid)
      monitors = Map.put(monitors, ref, name)
      processes = Map.put(processes, name, pid)
      {:noreply, {processes, monitors}}
    end
  end

  @impl true
  def handle_info(
    {:DOWN, ref, :process, _pid, _reason}, {processes, monitors}
  ) do
    {name, monitors} = Map.pop(monitors, ref)
    Logger.info("Process down: #{name}")

    {_pid, processes} = Map.pop(processes, name)
    # if Process.alive?(pid) do
    #   case Shell.Command.status(pid) do
    #     {:running, _} -> GenServer.stop(pid)
    #     _ -> 1
    #   end
    
    {:noreply, {processes, monitors}}
  end  

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

end
