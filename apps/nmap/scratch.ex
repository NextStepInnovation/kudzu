defmodule Nmap.Scratch do
  defstruct [
    # Function to be called upon success (i.e. exit status of 0). If
    # the function returns :ok, then the Nmap.Process GenServer stops,
    # otherwise, it continues to run.
    :success,
    # Function to be called upon failure (i.e. exit status != 0). If
    # the function returns :ok, then the Nmap.Process GenServer stops,
    # otherwise, it continues to run.
    :failure,
    
    # ----------------------------------------------------------------
    # TARGET SPECIFICATION
    # 
    # Can pass hostnames, IP addresses, networks, etc.
    # Ex: scanme.nmap.org, microsoft.com/24, 192.168.0.1; 10.0.0-255.1-254
    :targets,                   # List of targets
    :iL,                        # Input from list of hosts/networks
    :iR,                        # Choose random targets
    :exclude,                   # Exclude hosts/network
    :excludefile,               # Exclude list from file

    
    # ----------------------------------------------------------------
    # HOST DISCOVERY
    # 
    :sL,        # List Scan - simply list targets to scan
    :sn,        # Ping Scan - disable port scan
    :Pn,        # Treat all hosts as online -- skip host discovery
    :PS,        # TCP SYN discovery to given ports
    :PA,        # TCP ACK discovery to given ports
    :PU,        # UDP discovery to given ports
    :PY,        # SCTP discovery to given ports
    :PE,        # ICMP echo discovery probe
    :PP,        # timestamp discovery probe
    :PM,        # netmask request discovery probe
    :PO,        # [protocol list]
    # 
    #   DNS
    :n,                    # Never do DNS resolution
    :R,                    # Always resolve [default: sometimes]
    :dns_servers,          # Specify custom DNS servers
    :system_dns,           # Use OS's DNS resolver
    :traceroute,           # Trace hop path to each host


    # ----------------------------------------------------------------
    # SCAN TECHNIQUES
    #
    # TCP
    :sS,                        # SYN scans
    :sT,                        # Connect() scans
    :sA,                        # ACK scans
    :sW,                        # Window scans
    :sM,                        # Maimon scans
    :sN,                        # Nullscans
    :sF,                        # FIN scans
    :sX,                        # Xmas scans
    :scanflags,                 # <flags>: Customize TCP scan flags
    # 
    # UDP
    :sU,                        # UDP Scan
    # 
    # SCTP
    :sY,                        # INIT scans
    :sZ,                        # COOKIE-ECHO scans
    # 
    # Other
    :sI,                        # <zombie host[:probeport]>: Idle scan
    :sO,                        # IP protocol scan
    :b,                         # <FTP relay host>: FTP bounce scan


    # ----------------------------------------------------------------
    # PORT SPECIFICATION AND SCAN ORDER
    # 
    :p, # <port ranges>: Only scan specified ports
        # Ex: -p22; -p1-65535; -p U:53,111,137,T:21-25,80,139,8080,S:9
    # 
    # <port ranges>: Exclude the specified ports from scanning
    :exclude_ports,
    # 
    :F,           # Fast mode - Scan fewer ports than the default scan
    :r,           # Scan ports consecutively - don't randomize
    :top_ports,   # <number>: Scan <number> most common ports
    :port_ratio,  # <ratio>: Scan ports more common than <ratio>


    # ----------------------------------------------------------------
    # SERVICE/VERSION DETECTION
    :sV,         #  Probe open ports to determine service/version info
    # 
    # <level>: Set from 0 (light) to 9 (try all probes)
    :version_intensity,
    # Limit to most likely probes (intensity 2)
    :version_light,
    # Try every single probe (intensity 9)
    :version_all,
    # Show detailed version scan activity (for debugging)
    :version_trace,


    # ----------------------------------------------------------------
    # SCRIPT SCAN
    :sC,                        # equivalent to --script=default

    # <Lua scripts>: <Lua scripts> is a comma separated list of
    # directories, script-files or script-categories
    :script,

    # <n1=v1,[n2=v2,...]>: provide arguments to scripts
    :script_args,
    # filename: provide NSE script args in a file
    :script_args_file,
    # Show all data sent and received
    :script_trace,
    # Update the script database.
    :script_updatedb,
    

    # ----------------------------------------------------------------
    # OS DETECTION
    # 
    :O,                      # Enable OS detection
    :osscan_limit,           # Limit OS detection to promising targets
    :osscan_guess,           # Guess OS more aggressively


    # ----------------------------------------------------------------
    # TIMING AND PERFORMANCE
    # 
    # Options which take <time> are in seconds, or append 'ms'
    # (milliseconds), 's' (seconds), 'm' (minutes), or 'h' (hours) to
    # the value (e.g. 30m).
    #
    :T,                     # 0..5: Set timing template (higher is faster)
    :min_hostgroup,         # <size>: Parallel host scan group sizes
    :max_hostgroup,         # <size>: Parallel host scan group sizes
    :min_parallelism,       # <numprobes>: Probe parallelization
    :max_parallelism,       # <numprobes>: Probe parallelization
    :min_rtt_timeout,       # <time>: Specifies probe round trip time.
    :max_rtt_timeout,       # <time>: Specifies probe round trip time.
    :initial_rtt_timeout,   # <time>: Specifies probe round trip time.
    # <tries>: Caps number of port scan probe retransmissions.
    :max_retries,
    # <time>: Give up on target after this long
    :host_timeout, 
    :scan_delay,                # <time>: Adjust delay between probes
    :max_scan_delay,            # <time>: Adjust delay between probes
    # <number>: Send packets no slower than <number> per second
    :min_rate,
    # <number>: Send packets no faster than <number> per second
    :max_rate,


    # ----------------------------------------------------------------
    # FIREWALL/IDS EVASION AND SPOOFING
    # 
    :f,           # <val>: fragment packets
    :mtu,         # <val>: optional MTU for packet fragmentation
    :D,           # <decoy1,decoy2[,ME],...>: Cloak a scan with decoys
    :S,           # <IP_Address>: Spoof source address
    :e,           # <iface>: Use specified interface
    :g,           # <portnum>: Use given source port number
    :source_port, # <portnum>: Use given source port number
    # <url1,[url2],...>: Relay connections through HTTP/SOCKS4 proxies
    :proxies,
    # <hex string>: Append a custom payload to sent packets
    :data,
    # <string>: Append a custom ASCII string to sent packets
    :data_string,
    :data_length,  # <num>: Append random data to sent packets
    :ip_options,   # <options>: Send packets with specified ip options
    :ttl,          # <val>: Set IP time-to-live field
    # <mac address/prefix/vendor name>: Spoof your MAC address
    :spoof_mac,
    :badsum,         # Send packets with a bogus TCP/UDP/SCTP checksum


    # ----------------------------------------------------------------
    # OUTPUT
    # 
    :oN,        # <file>: Output scan in normal to the given filename.
    :oX,        # <file>: Output scan in XML to the given filename.
    :oS, # <file>: Output scan in s|<rIpt kIddi3 to the given filename.
    :oG, # <file>: Output scan in Grepable format to the given filename.
    :oA, # <basename>: Output in the three major formats at once
    :v, # Increase verbosity level (use -vv or more for greater effect)
    :d, # Increase debugging level (use -dd or more for greater effect)
    # Display the reason a port is in a particular state
    :reason,
    :open,          # Only show open (or possibly open) ports
    :packet_trace,  # Show all packets sent and received
    :iflist,        # Print host interfaces and routes (for debugging)
    :append_output, # Append to rather than clobber specified output files
    :resume,        # <filename>: Resume an aborted scan
    # <path/URL>: XSL stylesheet to transform XML output to HTML
    :stylesheet,
    # Reference stylesheet from Nmap.Org for more portable XML
    :webxml,
    # Prevent associating of XSL stylesheet w/XML output
    :no_stylesheet,


    # ----------------------------------------------------------------
    # MISC
    # 
    :ipv6,                      # 6: Enable IPv6 scanning
    # "Aggressive": Enable OS detection, version detection, script
    # scanning, and traceroute
    :A,
    # <dirname>: Specify custom Nmap data file location
    :datadir,
    :servicedb,          # Specify custom services file
    :versiondb,          # Specify custom service probes file
    :send_eth,           # Send using raw ethernet frames
    :send_ip,            # Send using IP packets
    :privileged,         # Assume that the user is fully privileged
    :unprivileged,       # Assume the user lacks raw socket privileges
    :V,                  # Print version number
   ]
  # for {k, v} <- Map.from_struct(post), v != nil, into: %{}, do: {k, v}

  @type path() :: String.t()
  @type url() :: String.t()
  @type strlist() :: [String.t()]
  @type portlist() :: [String.t() | integer]

  @typedoc """
  
  Type that represents the input parameters of the nmap network
  scanner. Nearly one-to-one with the actual command line
  options/arguments.

  A few custom types are used:

  - `path :: String.t()`
    : File-system path
  - `url :: String.t()`
    : URL
  - `strlist :: [String.t()]`
    : List of strings
  - `portlist :: [String.t() | integer]`
    : List of ports, given as either integers or binaries (e.g. "125",
      "T:125", or "U:125")

  Also, `String.t()` is used to designate human-readable strings and
  `binary` is used to designate actual potential binary data.
  
  """
  @type t :: %Nmap.Scratch{
    success: function,
    failure: function,
    targets: list,
    iL: path,
    iR: integer,
    exclude: strlist,
    excludefile: path,

    # ----------------------------------------------------------------
    # HOST DISCOVERY
    # 
    sL: boolean,
    sn: boolean,
    Pn: boolean,
    PS: portlist,
    PA: portlist,
    PU: portlist,
    PY: portlist,
    PE: boolean,
    PP: boolean,
    PM: boolean,
    PO: strlist,
    # 
    #   DNS
    n: boolean,
    R: boolean,
    dns_servers: strlist,
    system_dns: boolean,
    traceroute: boolean,

    # ----------------------------------------------------------------
    # SCAN TECHNIQUES
    #
    # TCP
    sS: boolean,
    sT: boolean,
    sA: boolean,
    sW: boolean,
    sM: boolean,
    sN: boolean,
    sF: boolean,
    sX: boolean,
    scanflags: String.t(),
    # 
    # UDP
    sU: boolean,
    # 
    # SCTP
    sY: boolean,
    sZ: boolean,
    # 
    # Other
    sI: strlist,
    sO: boolean,
    b: String.t(),

    # ----------------------------------------------------------------
    # PORT SPECIFICATION AND SCAN ORDER
    #
    p: portlist, 
    exclude_ports: portlist,
    F: boolean,
    r: boolean,
    top_ports: integer,
    port_ratio: number,

    # ----------------------------------------------------------------
    # SERVICE/VERSION DETECTION
    sV: boolean,
    version_intensity: 0..9,
    version_light: boolean,
    version_all: boolean,
    version_trace: boolean,

    # ----------------------------------------------------------------
    # SCRIPT SCAN
    sC: boolean,
    script: strlist,
    script_args: String.t(),
    script_args_file: path,
    script_trace: boolean,
    script_updatedb: boolean,
    
    # ----------------------------------------------------------------
    # OS DETECTION
    # 
    O: boolean,
    osscan_limit: boolean,
    osscan_guess: boolean,

    # ----------------------------------------------------------------
    # TIMING AND PERFORMANCE
    # 
    # Options which take <time> are in seconds, or append 'ms'
    # (milliseconds), 's' (seconds), 'm' (minutes), or 'h' (hours) to
    # the value (e.g. 30m).
    #
    T: 0..5,
    min_hostgroup: integer,
    max_hostgroup: integer,
    min_parallelism: integer,
    max_parallelism: integer,
    min_rtt_timeout: String.t(),
    max_rtt_timeout: String.t(),
    initial_rtt_timeout: String.t(),
    max_retries: integer,
    host_timeout: String.t(),
    scan_delay: String.t(),
    max_scan_delay: String.t(),
    min_rate: integer,
    max_rate: integer,

    # ----------------------------------------------------------------
    # FIREWALL/IDS EVASION AND SPOOFING
    # 
    f: 1..2,
    mtu: integer, # multiple of 8
    D: strlist,
    S: String.t(),
    e: String.t(),
    g: integer,
    source_port: integer,
    proxies: strlist,
    data: binary,
    data_string: String.t(),
    data_length: integer,
    ip_options: binary,
    ttl: integer,
    spoof_mac: String.t(),
    badsum: boolean,

    # ----------------------------------------------------------------
    # OUTPUT
    #
    oN: path,
    oX: path,
    oS: path,
    oG: path,
    oA: path,
    v: 1..3,
    d: 1..3,
    reason: boolean,
    open: boolean,
    packet_trace: boolean,
    iflist: boolean,
    append_output: boolean,
    resume: path,
    stylesheet: path | url,
    webxml: boolean,
    no_stylesheet: boolean,

    # ----------------------------------------------------------------
    # MISC
    # 
    ipv6: boolean,
    A: boolean,
    datadir: path,
    servicedb: path,
    versiondb: path,
    send_eth: boolean,
    send_ip: boolean,
    privileged: boolean,
    unprivileged: boolean,
    V: boolean,
  }

  @short_booleans [
    :sL, :sn, :Pn, :PE, :PP, :PM, :n, :R, :sS, :sT, :sA, :sW, :sM,
    :sN, :sF, :sX, :sU, :sY, :sZ, :sO, :F, :r, :sV, :sC, :O, :A, :V,
  ]

  @long_booleans [
    :system_dns, :traceroute, :version_light,
    :version_all, :version_trace, :script_trace, :script_updatedb, 
    :osscan_limit, :osscan_guess, :badsum, :webxml, :no_stylesheet,
    :ipv6, :send_eth, :send_ip, :privileged, :unprivileged, 
    :reason, :open, :packet_trace, :iflist, :append_output,
  ]

  @portlists [
    :PS, :PA, :PU, :PY, :p, :exclude_ports,
  ]

  @strlists [
    :PO, :dns_servers, :script, :D, :proxies,
    :exclude,
  ]

  @maps [
    :script_args,
  ]

  @ranges %{
    version_intensity: 0..9,
    T: 0..5,
    f: 1..2,
    v: 1..3,
    d: 1..3,
  }

  def transform_portlist(list) when is_list(list) do
    with {:ok, ports} <- Utils.all_ok_transform(list, &Utils.maybe_string/1),
         arg_value <- ports |> Enum.join(",") do
      {:ok, arg_value}
    end
  end
  def transform_portlist(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list
    |> transform_portlist
  end
  def transform_portlist(nonlist), do: {:error, {:not_a_list, nonlist}}

  def transform_strlist(list) when is_list(list) do
    with {:ok, strings} <- Utils.all_ok_transform(list, &Utils.maybe_string/1),
         arg_value <- strings |> Enum.join(",") do
      {:ok, arg_value}
    end
  end
  def transform_strlist(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list
    |> transform_strlist
  end
  def transform_strlist(nonlist), do: {:error, {:not_a_list, nonlist}}

  def transform_map(map) when is_map(map) do
    map
    |> Enum.map(fn({k, v}) -> "#{k}=#{v}" end)
    |> Enum.join(",")
  end
  def transform_map(nonmap), do: {:error, {:not_a_map, nonmap}}

  def params_set(atoms, params) do
    atoms
    |> Enum.filter(fn(atom) -> Map.has_key?(params, atom) end )
    |> Enum.filter(fn(atom) -> Map.get(params, atom) end)
  end

  @spec to_args(Nmap.Scratch.t()) :: String.t()
  def to_args(params) do
    short_booleans = @short_booleans
    |> params_set(params)
    |> Enum.map(fn(arg) -> "-#{arg}" end)
    |> Enum.join(" ")

    long_booleans = @long_booleans
    |> params_set(params)
    |> Enum.map(fn(arg) -> "--#{arg}" end)
    |> Enum.join(" ")

    portlists = @portlists
    |> params_set(params)
    |> Enum.map(
      fn(arg) -> {arg, transform_portlist(Map.get(params, arg))} end
    )
    |> Enum.group_by(fn({arg, {atom, result}}) -> atom end)

    strlists = @strlists
    |> params_set(params)
    |> Enum.map(
      fn(arg) -> {arg, transform_strlist(Map.get(params, arg))} end
    )
    |> Enum.group_by(fn({arg, {atom, result}}) -> atom end)

    
    {:ok, [short_booleans, long_booleans] |> Enum.join(" ")}
  end
end
