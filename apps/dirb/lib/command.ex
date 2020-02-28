defmodule Dirb.Command do
  use Shell.Command, command: "dirb"

  @header_regexes [
    ~r{START_TIME: (?<start_time>.*?)\n},
    ~r{URL_BASE: (?<url_base>.*?)\n},
    ~r{WORDLIST_FILES: (?<wordlist_files>.*?)\n},
    ~r{OPTION: (?<option>.*)\n},
    ~r{USER_AGENT: (?<user_agent>.*)\n},
  ]

  @url_regexes [
    url: ~r{\+ (?<url>http[s]?://.*?)\s+\(CODE:(?<code>\d+)\|SIZE:(?<size>\d+)\)},
    dir: ~r{==> DIRECTORY: (?<url>http[s]?://.*)},
  ]

  def parse_output(output) when is_list(output) do
    output
    |> output_binary
    |> parse_output
  end
  def parse_output(output) when is_binary(output) do
    header = @header_regexes
    |> Enum.map(&Regex.named_captures(&1, output))
    |> Enum.reduce(&Map.merge/2)

    urls = @url_regexes
    |> Enum.map(fn({t, r}) -> {t, RegUtil.scan_groups(r, output)} end)
    |> Enum.into(%{})

    %{header: header, urls: urls}
  end

  @impl true
  def handle_status(%{output: output, success: success, failure: failure}) do
    case {success, failure} do
      {nil, nil} -> {:running, output |> parse_output}
      {success, nil} -> {:success, success}
      {nil, failure} -> {:failure, failure}
    end
  end

  @impl true
  def handle_exit(status, %{output: output}) do
    data = output |> parse_output
    case status do
      0 -> {:success, data}
      _ -> {:failure, data}
    end
  end
end
