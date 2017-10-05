use Mix.Config

config :alchemetrics, backends: [
  {FakeBackend, [some: "options"]}
]
