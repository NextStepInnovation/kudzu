# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#
config :nmap,
  exec_path: "/usr/bin/nmap",
  nse_scripts_path: "/usr/share/nmap/scripts"

config :fping,
  exec_path: "/usr/bin/fping"

config :dirb,
  exec_path: "/usr/bin/dirb"

config :nikto,
  exec_path: "/usr/bin/nikto"

# config :wmiexec,
#   exec_path: "/usr/bin/impacket-wmiexec"

import_config "#{Mix.env()}.exs"
