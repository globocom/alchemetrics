defmodule Alchemetrics.LoggerReporter do
  use Alchemetrics.CustomReporter
  require Logger

  def init(options) do
    Logger.debug "Starting #{__MODULE__} with following options: #{inspect options}"
    {:ok, options}
  end

  def report(metadata, datapoint, value, options) do
    metadata = Enum.into(metadata, %{})
    base_report = %{datapoint: datapoint, value: value, options: options}
    Logger.debug Map.merge(base_report, metadata)
    {:ok, options}
  end
end

