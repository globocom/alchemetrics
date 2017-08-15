use Mix.Config

config :alchemetrics, reporter_list: [
  [module: FakeReporter, opts: [some: "options"]]
]