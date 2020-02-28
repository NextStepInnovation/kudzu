defmodule Shell.Bash do
  use Shell.Command, command: "bash"

  @impl true
  def prepare_args(%{args: args}) do
    with {:ok, arglist} <- args |> Args.from_list do
      command = arglist
      |> Enum.join(" ")

      {:ok, ["-c", command]}
    end
  end
end
