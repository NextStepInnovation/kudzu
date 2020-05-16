defmodule IP do
  def regex_only do
    ~r/^((?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d))$/
  end

  def regex do
    ~r/(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)/
  end

  @doc """

  Given a line (binary), return the IP addresses found in it.  IP
  addresses must not have anything other than spaces and punctuation
  (excluding periods) around them.

  Examples:

    iex> IP.parse_ips("192.168.1.1 10.0.0.1")
    ["192.168.1.1", "10.0.0.1"]
  
    iex> IP.parse_ips("192.168.1.1x")
    []

    iex> IP.parse_ips("192.168.1.1, 10.0.0.1")
    ["192.168.1.1", "10.0.0.1"]

    iex> IP.parse_ips("192.168.1.1. 10.0.0.1")
    ["10.0.0.1"]

    iex> IP.parse_ips("192.168.1.1:10.0.0.1")
    ["192.168.1.1", "10.0.0.1"]
  """
  
  def parse_ips(line) when is_binary(line) do
    Regex.split(~r{[^\d.\w]}, line)
    |> Enum.filter(fn(v) -> Regex.match?(IP.regex_only, v) end)
    # Regex.scan(IP.regex, line)
    # |> Enum.concat
    # |> String.split
    # |> Enum.filter(fn(v) -> Regex.match?(IP.regex, v) end)
  end
end
