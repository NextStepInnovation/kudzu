defmodule Shell.Command do

  @doc """

  Prepare the Shell.Command state map prior to running the Port.
  E.g. might be used to set up a temporary output file to be parsed
  after the command has completed.

  By default, returns state as is.

  """
  @callback command_init(map) :: {:ok, map} | {:error, term}

  @doc """

  Given a List of arguments, convert to a list of command-line
  arguments as strings, suitable for the `Port.open` command.

  By default, use the output of the `Args.from_list` function
  directly.

  """
  @callback command_args(map) :: {:ok, list} | {:error, term}

  @doc """

  Given an exit status code and the current state of the GenServer,
  return either

  - {:success, term} where term is the thing associated with a
    successful run of this Shell.Command or

  - {:failure, term} where term is thing associated with an
    unsuccessful run (usually an :error)

  """
  @callback handle_exit(integer, map) :: {:success, term} | {:failure, term}

  @doc """

  Given the the current state of the GenServer, provide status
  information for the process. Should return either

  - `{:running, term}` where term is something that indicates the
    current status of the running process (default: stdout + stderr)

  - `{:success, term}` where term is the thing associated with a
    successful run of this Shell.Command

  - `{:failure, term}` where term is thing associated with an
    unsuccessful run (usually an :error)

  """
  @callback handle_status(map) ::
            {:running, term} | {:success, term} | {:failure, term}

  @callback exec_path() :: {:ok, binary} | :error

  @optional_callbacks command_args: 1,
                      handle_exit: 2,
                      handle_status: 1,
                      exec_path: 0

  @spec __using__(keyword) ::
          {:__block__, [],
           [
             {:@, [...], [...]}
             | {:def, [...], [...]}
             | {:defoverridable, [...], [...]}
             | {:require, [...], [...]}
             | {:use, [...], [...]},
             ...
           ]}
  defmacro __using__(opts) do
    command = Keyword.get(opts, :command, "")

    port_options = Keyword.get(
      opts, :port_options, [:binary, :exit_status, :stderr_to_stdout]
    )

    quote do
      use GenServer, restart: :temporary
      @behaviour Shell.Command

      @command unquote(command)
      @port_options unquote(port_options)

      require Logger

      def start_link(args) do
        GenServer.start_link(__MODULE__, args)
      end

      def output_binary(state) when is_map(state) do
        output_binary(state[:output])
      end
      def output_binary(output) when is_list(output) do
        output
        |> Enum.reverse
        |> Enum.join("\n")
      end

      def exec_path do
        case System.find_executable(@command) do
          nil ->
            Logger.error("Could not find executable: #{@command}")
            :error
          path -> {:ok, path}
        end
      end
      defoverridable exec_path: 0

      # ----------------------------------------------------------------------
      # GenServer code
      # ----------------------------------------------------------------------

      @impl true
      def init(args) do
        case exec_path() do
          {:ok, path} ->
            {:ok,
             %{
               port: nil,
               port_info: nil,
               exec_path: path,
               options: @port_options,
               args: args,
               output: [],
               output_times: [],
               finished: false,
               success: nil,
               failure: nil,
               times: %{
                 start: nil,
                 finish: nil,
                 terminated: nil,
               }
             },
             {:continue, :start_shell}}
          :error ->
            {:stop, :bad_exec_path}
        end
      end

      # ------------------------------------------------------------
      # command_init callback
      #
      # ------------------------------------------------------------
      @spec command_init(map) :: {:ok, map} | {:error, term}
      def command_init(state), do: {:ok, state}

      defoverridable command_init: 1

      # ------------------------------------------------------------
      # command_args callback
      #
      # ------------------------------------------------------------
      @spec command_args(map) :: {:ok, list} | {:error, term}
      def command_args(%{args: args}), do: args |> Args.from_list

      defoverridable command_args: 1

      @impl true
      def handle_continue(:start_shell, %{args: args,
                                          options: options,
                                          times: times,
                                          exec_path: exec_path} = state) do
        with {:ok, state} <- command_init(state),
             {:ok, arglist} <- command_args(state) do
          port = Port.open(
            {:spawn_executable, exec_path}, options ++ [args: arglist]
          )
          port_info = Port.info(port)

          state = state
          |> Map.put(:port, port)
          |> Map.put(:port_info, port_info)
          |> Map.put(:times, times |> Map.merge(%{start: Timex.now()}))
          {:noreply, state}
        else
          {:error, error} ->
            {:stop,
             {:bad_args, error},
             state
             |> Map.put(:failure, error)
             |> Map.put(:times, times |> Map.merge(%{terminated: Timex.now()}))
            }
        end
      end

      def handle_exit(status, state) do
        case status do
          0 -> {:success, state |> output_binary}
          other -> {:failure, state |> output_binary}
        end
      end
      defoverridable handle_exit: 2

      @impl true
      def handle_info({_port, {:exit_status, status}}, %{times: times} = state) do
        Logger.info("#{state[:exec_path]} exited with status #{status}...")
        state = case handle_exit(status, state) do
                  {:success, success} ->
                    state
                    |> Map.put(:success, success)
                  {:failure, failure} ->
                    state
                    |> Map.put(:failure, failure)
                end
        {:noreply,
         state
         |> Map.put(:finished, true)
         |> Map.put(:times, times |> Map.merge(%{finished: Timex.now()}))
        }
      end

      @impl true
      def handle_info({_port, {:data, content}}, %{output: output,
                                                   output_times: times} = state) do
        state = state
        |> Map.put(:output, [content | output])
        |> Map.put(:output_times, [Timex.now() | times])
        {:noreply, state}
      end

      @impl true
      def handle_call(:output, _from, state) do
        {:reply, state |> output_binary, state}
      end

      @spec handle_status(map) ::
            {:running, term} | {:success, term} | {:failure, term}
      def handle_status(%{success: success, failure: failure} = state) do
        case {success, failure} do
          {nil, nil} -> {:running, state |> output_binary}
          {success, nil} -> {:success, success}
          {nil, error} -> {:failure, error}
        end
      end
      defoverridable handle_status: 1

      @impl true
      def handle_call(:status, _from, state) do
        case handle_status(state) do
          {:running, status} ->
            {:reply, {:running, status}, state}
          {:success, success} ->
            {:reply, {:success, success}, state}
          {:failure, failure} ->
            {:reply, {:failure, failure}, state}
        end
      end

      @impl true
      def terminate(_reason, %{finished: finished, exec_path: exec_path,
                               port_info: port_info}) do
        Logger.info("#{exec_path} terminated...")
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
  end

  # ----------------------------------------------------------------------
  # Client code
  # ----------------------------------------------------------------------

  def status(process) do
    GenServer.call(process, :status)
  end

  def output(process) when is_pid(process) do
    GenServer.call(process, :output)
  end

  def halt(process) do
    GenServer.stop(process, :shutdown)
  end

end
