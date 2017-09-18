defmodule Alchemetrics.ConsoleReporter do
  use Alchemetrics.CustomReporter

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

