# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :metrics, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:metrics, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

config :alchemetrics, reporter_list: [
  [module: FakeReporter, opts: [some: "options"]]
]

polling_interval = 5_000
memory_stats     = ~w(atom binary ets processes total)a
# config :exometer_core,
#   predefined: [
#     {
#       [:erlang, :memory],
#       {:function, :erlang, :memory, [], :proplist, memory_stats},
#       []
#     },
    # {
    #   [:erlang, :statistics],
    #   {:function, :erlang, :statistics, [:'$dp'], :value, [:run_queue]},
    #   []
    # },
  #]
#   reporters: [
#     "Elixir.Alchemetrics.ConsoleReporter": [hostname: 'localhost', port: 8125]
#   ],
#   report: [
#     subscribers: [
#       {
#         Elixir.Alchemetrics.ConsoleReporter,
#         [:erlang, :memory], memory_stats, polling_interval, true, [:x]
#       }
#     ]
#   ]




# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
