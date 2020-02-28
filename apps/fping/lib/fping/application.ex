defmodule Fping.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Fping.Worker.start_link(arg)
      # {Fping.Worker, arg}
      {Fping.Server, name: Fping.Server},
      {DynamicSupervisor, name: Fping.ProcessSupervisor,
       strategy: :one_for_one},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Fping.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
