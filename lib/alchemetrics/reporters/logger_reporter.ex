defmodule Alchemetrics.LoggerReporter do
  use Alchemetrics.CustomReporter
  require Logger

  def init(options) do
    Logger.debug "Starting #{__MODULE__} with following options: #{inspect options}"
    {:ok, options}
  end

  def report(public_name, metric, value, options) do
    Logger.debug "Reporting: #{inspect %{name: public_name, metric: metric, value: value, options: options}}"
    {:ok, options}
  end
end

