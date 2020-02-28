defmodule Fping do
  @moduledoc """
  Documentation for `Fping`.
  """

  def exec_path do
    Application.fetch_env!(:fping, :exec_path)
  end

end
