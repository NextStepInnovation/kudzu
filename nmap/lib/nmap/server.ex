defmodule Nmap.Server do
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  # ------------------------------------------------------------
  # Client API
  # ------------------------------------------------------------
  def fetch(server, name) do
    GenServer.call(server, {:fetch, name})
  end

  def status(server, name) do
    GenServer.call(server, {:status, name})
  end
  def status(server) do
    GenServer.call(server, :status)
  end

  def start(server, name, args) do
    GenServer.cast(server, {:start, name, args}) 
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
  def handle_call({:fetch, name}, _from, {processes, _} = state) do
    # IO.inspect(processes)
    {:reply, Map.fetch(processes, name), state}
  end

  @impl true
  def handle_call({:status, name}, _from, {processes, _} = state) do
    # IO.inspect(processes)
    case Map.fetch(processes, name) do
      {:ok, pid} -> {:reply, Nmap.Process.status(pid), state}
      _ -> {:reply, :error, state}
    end
  end

  @impl true
  def handle_call(:status, _from, {processes, _} = state) do
    status = processes
    |> Enum.map(
      fn({name, pid}) ->
        case Nmap.Process.status(pid) do
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
  def handle_cast({:start, name, args}, {processes, monitors}) do
    if Map.has_key?(processes, name) do
      {:noreply, {processes, monitors}}
    else
      # IO.inspect(args)
      {:ok, pid} = DynamicSupervisor.start_child(
        Nmap.ProcessSupervisor, {Nmap.Process, args}
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
    processes = Map.delete(processes, name)
    {:noreply, {processes, monitors}}
  end  

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

end
