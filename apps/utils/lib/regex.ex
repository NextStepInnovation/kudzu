defmodule RegUtil do
  def scan_groups(regex, content) do
    Regex.scan(regex, content)
    |> Enum.map(&List.first/1)
    |> Enum.map(&Regex.named_captures(regex, &1))
  end
end
