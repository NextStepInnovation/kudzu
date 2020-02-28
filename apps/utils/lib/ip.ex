defmodule IP do
  def regex do
    ~r/^(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$/
  end

  def parse_ips(line) when is_binary(line) do
    line
    |> String.split
    |> Enum.filter(fn(v) -> Regex.match?(IP.regex, v) end)
  end
end
