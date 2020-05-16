defmodule RegUtils do

  @doc """

  Given a regular expression containing named captures and a block of
  binary content, return a list of maps

  Examples:

    iex> RegUtils.scan_groups(~r{a (?<b>.*?) c}, "a b c a d c")
    [%{"b" => "b"}, %{"b" => "d"}]
  
  """
  
  @spec scan_groups(Regex.T, binary) :: list[map]
  def scan_groups(regex, content) do
    Regex.scan(regex, content)
    |> Enum.map(&List.first/1)
    |> Enum.map(&Regex.named_captures(regex, &1))
  end
end
