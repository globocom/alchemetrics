defmodule Alchemetrics.ConsoleReporter do
  use Alchemetrics.CustomReporter

  @moduledoc """
  Backend to print the datasets measurements on the console.

  ## Using it with IEx

  ```elixir
  iex(1)> Alchemetrics.ConsoleReporter.enable
  :ok
  Starting Elixir.Alchemetrics.ConsoleReporter with following options: []
  iex(2)> Alchemetrics.increment(:my_metric)
  :ok
  iex(3)> Alchemetrics.increment(:my_metric)
  :ok
  iex(4)> Alchemetrics.increment(:my_metric)
  :ok
  iex(5)> %{datapoint: :last_interval, name: :my_metric, options: [], value: 3}
  %{datapoint: :total, name: :my_metric, options: [], value: 3}
  ```

  ## Starting on application boot
  To start `Alchemetrics.ConsoleBackend` at application boot, just add it to the `:reporter_list` config option. Start up parameters are set in `opts` option.

  ```elixir
  # on config/config.exs
  config :alchemetrics, reporter_list: [
    [module: Alchemetrics.ConsoleReporter, opts: []]
  ]
  ```
  """

  def init(options) do
    IO.puts "Starting #{__MODULE__} with following options: #{inspect options}"
    {:ok, options}
  end

  def report(metadata, datapoint, value, options) do
    metadata = Enum.into(metadata, %{})
    base_report = %{datapoint: datapoint, value: value, options: options}
    IO.inspect Map.merge(base_report, metadata)
    {:ok, options}
  end
end

