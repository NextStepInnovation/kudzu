defmodule Windows.Credentials do
  @doc """

  Given a term (and optionally a default term), attempt to coerce it
  into a binary. If not possible, then return error (or optional
  binary).

  Examples:

    iex> Wincred.new(:a)
    {:ok, %{}}

  """

  @spec __struct__ :: %Windows.Credentials{
    domain: binary, username: binary, password: binary
  }
  defstruct [domain: ".", username: "", password: ""]

end

defimpl String.Chars, for: Windows.Credentials do
  def to_string(cred) do
    "#{cred.domain}\\#{cred.username}:#{cred.password}"
  end
end
