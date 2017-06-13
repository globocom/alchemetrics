defmodule Metrics.EctoLogger do
  def record_metric(entry) do
    Metrics.measure_time("database", "query_time", entry.query_time |> to_microseconds)
    Metrics.measure_time("database", "queue_time", entry.query_time |> to_microseconds)
    Metrics.count("database", "query_count")
  end

  defp to_microseconds(value) do
    System.convert_time_unit(value || 0, :native, :microsecond)
  end
end
