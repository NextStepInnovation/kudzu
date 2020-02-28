defmodule Shell.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Shell.Worker.start_link(arg)
      # {Shell.Worker, arg}
      {Shell.Server, name: Shell.Server},
      {DynamicSupervisor, name: Shell.CommandSupervisor,
       strategy: :one_for_one},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Shell.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
