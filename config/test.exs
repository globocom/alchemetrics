use Mix.Config

config :alchemetrics, reporter_list: [
  [module: FakeBackend, opts: [some: "options"]]
]
