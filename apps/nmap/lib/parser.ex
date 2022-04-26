defmodule Nmap.XmlParser do
  @moduledoc """
  nmap XML output parser
  """
  require Logger
  import SweetXml

  @doc """

  Parse an nmap XML output file

  """
  @spec parse_nmap_path(binary) :: {:ok, map} | {:error, term}
  def parse_nmap_path(path) when is_binary(path) do
    Logger.info "Parsing nmap XML path #{path}"
    with {:ok, doc} <- File.read(path),
         {:ok, nmap} <- parse_nmap_binary(doc) do
      {:ok, nmap}
    end
  end

  @spec parse_nmap_binary(binary) ::
          {:error,
           {:fatal_xml, any}
           | {:nmap_xml_parsing,
              %{:__exception__ => true, :__struct__ => atom, optional(atom) => any}}
           | {:xml_parsing, %{:__exception__ => true, :__struct__ => atom, optional(atom) => any}}}
          | {:ok, map}
  def parse_nmap_binary(doc) when is_binary(doc) do
    Logger.info "Parsing nmap XML data #{String.length(doc)}"
    with {:ok, doc_elem} <- parse_xml(doc),
         {:ok, nmap} <- parse_nmap_elem(doc_elem) do
      {:ok, nmap}
    end
  end

  @spec parse_progress(binary) :: list
  def parse_progress(doc) when is_binary(doc) do
    doc
    |> String.split("\n")
    |> Enum.map(fn(line) ->
      case parse_xml(line) do
        {:ok, parsed} ->
          case parsed |> xpath(~x"//taskprogress"o, task: ~x"./@task",
                time: ~x"./@time" |> transform_by(&maybe_epoch/1),
                percent: ~x"./@percent"fo, remaining: ~x"./@remaining"io,
                etc: ~x"./@etc" |> transform_by(&maybe_epoch/1)
              ) do
            nil -> nil
            progress -> progress
          end
        _ -> nil
      end
    end)
    |> Enum.filter(fn(v) -> v end)
  end

  @spec parse_xml(binary) ::
          {:error,
           {:fatal_xml, any}
           | {:xml_parsing,
              %{:__exception__ => true,
                :__struct__ => atom, optional(atom) => any}}}
          | {:ok,
             {:xmlElement, any, any, any, any, any, any, any, any, any, any, any}}
  def parse_xml(doc) when is_binary(doc) do
    try do
      parsed = parse(doc, quiet: true)
      {:ok, parsed}
    rescue
      error -> {:error, {:xml_parsing, error}}
    catch
      :exit, error -> {:error, {:fatal_xml, error}}
    end
  end

  @spec parse_nmap_elem(any) ::
          {:error,
           {:nmap_xml_parsing,
            %{:__exception__ => true, :__struct__ => atom, optional(atom) => any}}}
          | {:ok, map}
  def parse_nmap_elem(doc_elem) do
    try do
      {:ok, parse_nmap_elem!(doc_elem)}
    rescue
      error -> {:error, {:nmap_xml_parsing, error}}
    end
  end

  @spec maybe_epoch(
          nil
          | binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | char,
              binary | []
            )
        ) :: nil | binary | DateTime.t()
  def maybe_epoch(nil), do: nil
  def maybe_epoch(ts) when is_list(ts) do
    ts |> List.to_string |> maybe_epoch
  end
  def maybe_epoch(ts) when is_binary(ts) do
    if String.match?(ts, ~r"^\d+$") do
      case ts |> String.to_integer |> DateTime.from_unix do
        {:ok, utc} -> utc
        _ -> ts
      end
    else
      ts
    end
  end

  @spec maybe_atom(nil | binary | charlist) :: atom
  def maybe_atom(nil), do: nil
  def maybe_atom(w) when is_list(w), do: List.to_atom(w)
  def maybe_atom(w) when is_binary(w), do: String.to_atom(w)

  @spec transform_nmap(map) :: map
  def transform_nmap(nmap) do
    if Map.has_key?(nmap, :hosts) do
      hosts = nmap.hosts
      |> Enum.map(fn(h) -> %{h.addresses.ipv4.addr => h} end)
      |> merge_maps

      nmap
      |> Map.put(:hosts, hosts)
    else
      nmap
    end
  end

  @spec parse_nmap_elem!(any) :: map
  def parse_nmap_elem!(doc_elem) do
    doc_elem
    |> xpath(
      # ~x"//nmaprun"
      ~x"//nmaprun",
      hosts: ~x"." |> transform_by(&parse_hosts/1),
      scanner: ~x"./@scanner"s,
      args: ~x"./@args"s,
      start: ~x"./@start"s |> transform_by(&maybe_epoch/1),
      startstr: ~x"./@startstr"s,
      version: ~x"./@version"s,
      xmloutputversion: ~x"./@xmloutputversion"s,
      scaninfo: [
        ~x"./scaninfo"l,
        type: ~x"./@type"s,
        protocol: ~x"./@protocol"s |> transform_by(&maybe_atom/1),
        numservices: ~x"./@numservices"io,
        services: ~x"./@services"s,
      ],

      verbose: [
        ~x"./verbose"o,
        level: ~x"./@level"io,
      ],
      debugging: [
        ~x"./debugging"o,
        level: ~x"./@level"io,
      ],

      target: [
        ~x"./target"o,
        specification: ~x"./@specification"s,
        status: ~x"./@status"s,
        reason: ~x"./@reason"s,
      ],

      taskbegin: [
        ~x"./taskbegin"l,
        task: ~x"./@task",
        time: ~x"./@time" |> transform_by(&maybe_epoch/1),
        extrainfo: ~x"./@extrainfo",
      ],
      taskprogress: [
        ~x"./taskprogress"l,
        task: ~x"./@task",
        time: ~x"./@time" |> transform_by(&maybe_epoch/1),
        percent: ~x"./@percent"fo,
        remaining: ~x"./@remaining"io,
        etc: ~x"./@etc" |> transform_by(&maybe_epoch/1),
      ],
      taskend: [
        ~x"./taskend"l,
        task: ~x"./@task",
        time: ~x"./@time" |> transform_by(&maybe_epoch/1),
        extrainfo: ~x"./@extrainfo",
      ],

      runstats: [
        ~x"./runstats"o,
        finished: [
          ~x"./finished"o,
          time: ~x"./@time" |> transform_by(&maybe_epoch/1),
          timestr: ~x"./@timestr"s,
          elapsed: ~x"./@elapsed"fo,
          summary: ~x"./@summary"s,
          exit: ~x"./@exit"s,
        ],
        hosts: [
          ~x"./hosts"o,
          up: ~x"./@up"io,
          down: ~x"./@down"io,
          total: ~x"./@total"io,
        ],
      ]
    )
    |> transform_nmap
  end

  @spec filter_nil(any) :: list
  def filter_nil(children) do
    children
    |> Enum.filter(fn(v) -> not is_nil(v) end)
  end

  @spec merge_maps(any) :: map
  def merge_maps(children_with_nil) do
    # If all children are Maps, then merge children into single map,
    # else leave as list
    children = filter_nil children_with_nil
    if children |> Enum.all?(&is_map/1) do
      children
      |> Enum.reduce(%{}, &Map.merge/2)
    else
      children
      |> Enum.to_list
      |> (fn(l) -> %{"list" => l} end).()
    end
  end

  def transform_scripts(node) do
    scripts = node.scripts
    |> Enum.map(fn(s) -> %{s.id => s} end)
    |> merge_maps

    node
    |> Map.put(:scripts, scripts)
  end

  def transform_host(host) do
    ports = host.ports
    |> Enum.map(fn(p) -> %{p.port => transform_scripts(p)} end)
    |> merge_maps

    addresses = host.addresses
    |> Enum.map(fn(a) -> %{String.to_atom(a.addrtype) => a} end)
    |> merge_maps

    host
    |> transform_scripts
    |> Map.put(:ports, ports)
    |> Map.put(:addresses, addresses)
  end

  '''
  <!ELEMENT host	( status, address , (address | hostnames |
                          smurf | ports | os | distance | uptime |
                          tcpsequence | ipidsequence | tcptssequence |
                          hostscript | trace)*, times? ) >
  <!ATTLIST host
			starttime	%attr_numeric;	#IMPLIED
			endtime		%attr_numeric;	#IMPLIED
			comment		CDATA		#IMPLIED

  '''

  def parse_hosts(nmaprun_elem) do
    nmaprun_elem
    |> xpath(
      ~x"//nmaprun/host"l,
      starttime: ~x"./@starttime" |> transform_by(&maybe_epoch/1),
      endtime: ~x"./@endtime" |> transform_by(&maybe_epoch/1),

      addresses: [
        ~x"./address"l,
        addr: ~x"./@addr"s,
        addrtype: ~x"./@addrtype"s,
      ],

      hostnames: [
        ~x"./hostnames/hostname"l,
        name: ~x"./@name"s,
        type: ~x"./@type" |> transform_by(&maybe_atom/1),
      ],

      smurf: [
        ~x"./smurf"l,
        responses: ~x"./@responses"io,
      ],

      scripts: [
        ~x"./hostscript/script"l,
        id: ~x"./@id"s,
        output: ~x"./@output"s,
        data: ~x"." |> transform_by(&parse_script_node/1),
      ],

      ports: [
        ~x"./ports/port"l,
        protocol: ~x"@protocol" |> transform_by(&maybe_atom/1),
        port: ~x"@portid"io,

        state: [
          ~x"./state"o,
          state: ~x"./@state"s,
          reason: ~x"./@reason"s,
          reason_ttl: ~x"./@reason_ttl"s,
        ],

        owner: [
          ~x"./owner"o,
          name: ~x"./@name"s,
        ],

        service: [
          ~x"./service"o,
          name: ~x"./@name"s,
          product: ~x"./@product"s,
          extrainfo: ~x"./@extrainfo"s,
          ostype: ~x"./@ostype"s,
          method: ~x"./@method"s,
          conf: ~x"./@conf"s,
          cpes: ~x"./cpe/text()"ls,
        ],

        scripts: [
          ~x"./script"l,
          id: ~x"./@id"s,
          output: ~x"./@output"s,
          data: ~x"." |> transform_by(&parse_script_node/1),
        ],
      ],

      os: [
        ~x"./os"o,
        portused: [
          ~x"./portused"l,
          state: ~x"./@state"s,
          protocol: ~x"./@proto" |> transform_by(&maybe_atom/1),
          port: ~x"./@port"s,
        ],
        matches: [
          ~x"./osmatch"l,
          name: ~x"./@name"s,
          accuracy: ~x"./@accuracy"io,
          line: ~x"./@line"io,
          class: [
            ~x"./osclass"o,
            type: ~x"./@type"s,
            vendor: ~x"./@vendor"s,
            osfamily: ~x"./@osfamily"s,
            osgen: ~x"./@osgen"s,
            accuracy: ~x"./@accuracy"io,
            cpes: ~x"./cpe/text()"ls,
          ],
        ],
        fingerprints: [
          ~x"./osfingerprint"l,
          fingerprint: ~x"./@fingerprint"s,
        ],
      ],

      status: [
        ~x"./status"o,
        state: ~x"./@state" |> transform_by(&maybe_atom/1),
        reason: ~x"./@reason"s,
      ]
    )
    |> Enum.map(&transform_host/1)
  end

  def parse_script_node({:xmlElement, :table, _atom, _l, _ns, _locs, _int,
                          [], children, _, _, _}) do
    children
    |> Enum.map(&parse_script_node/1)
    |> merge_maps
  end

  def parse_script_node({:xmlElement, :table, _atom, _l, _ns, _locs, _int,
                          [{:xmlAttribute, :key, _, _, _,
                           _, _, _, key, _}], children, _, _, _}) do
    %{
      List.to_string(key) =>
      children
      |> Enum.map(&parse_script_node/1)
      |> merge_maps
    }

  end

  def parse_script_node({:xmlElement, :elem, _atom, _l, _ns, _locs, _int,
                          [], _, _, _, _} = elem) do
    elem |> xpath(~x"./text()"s)
  end

  def parse_script_node({:xmlElement, :elem, _atom, _l, _ns, _locs, _int,
                          [{:xmlAttribute, :key, _, _, _,
                           _, _, _, key, _}], _, _, _, _} = elem) do
    %{List.to_string(key) => elem |> xpath(~x"./text()"s)}
  end

  def parse_script_node({:xmlElement, :script, _atom, _l, _ns, _locs, _int,
                          _attr, children, _l2, _path, _atom2}) do
    children
    |> Enum.map(&parse_script_node/1)
    |> merge_maps
  end

  def parse_script_node(_rest) do
    # IO.puts(rest |> Tuple.to_list |> Enum.count)
    # IO.inspect(rest)
    nil
  end

end
