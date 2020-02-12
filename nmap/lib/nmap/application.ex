defmodule Nmap.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Nmap.Worker.start_link(arg)
      # {Nmap.Worker, arg}
      {Nmap.Server, name: Nmap.Server},
      {DynamicSupervisor, name: Nmap.ProcessSupervisor,
       strategy: :one_for_one},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nmap.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
