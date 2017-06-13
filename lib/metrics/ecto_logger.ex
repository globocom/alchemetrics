defmodule ElixirMetrics.EctoLogger do
  def record_metric(entry) do
    ElixirMetrics.measure_time("database", "query_time", entry.query_time |> to_microseconds)
    ElixirMetrics.measure_time("database", "queue_time", entry.query_time |> to_microseconds)
    ElixirMetrics.count("database", "query_count")
  end

  defp to_microseconds(value) do
    System.convert_time_unit(value || 0, :native, :microsecond)
  end
end
