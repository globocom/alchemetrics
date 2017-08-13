defmodule Alchemetrics.Exometer.Metric do

  @default_metrics %{
    p99: {:histogram, 99},
    p95: {:histogram, 95},
    avg: {:histogram, :mean},
    total: {:spiral, :count},
    last_interval: {:spiral, :one}
  }

  @erlang_metrics %{
    memory_atom: {:memory, :atom},
    memory_binary: {:memory, :binary},
    memory_ets: {:memory, :ets},
    memory_processes: {:memory, :processes},
    memory_total: {:memory, :total},
    statistics_runqueue: {:statistics, :run_queue}
  }

  @metrics Map.merge(@default_metrics, @erlang_metrics)
  

  @enforce_keys [:scope, :name, :value]
  
defstruct [:scope, :datapoints, :name, :value, metadata: %{}]

  def from_event(%Alchemetrics.Event{name: name, metrics: metrics, value: value, metadata: metadata}) do
    validate_metrics(metrics)

    metrics
    |> scopes_for
    |> Enum.map(fn scope ->
      %Alchemetrics.Exometer.Metric{name: [name, scope], datapoints: datapoints_for(scope, metrics), scope: scope, value: value, metadata: metadata}
    end)
  end

  def metric_from_scope(scope, datapoint) do
    case Enum.find(@metrics, fn({_, d}) -> d == {scope, datapoint} end) do
      nil -> nil
      {metric, _} -> metric
      _ -> nil
    end
  end

  defp datapoints_for(scope, metrics) do
    @metrics
    |> Enum.filter(fn {metric, {metric_scope, _}} -> scope == metric_scope && Enum.member?(metrics, metric) end)
    |> Enum.map(fn {_, {_, datapoint}} -> datapoint end)
  end

  defp validate_metrics(metrics) do
    metrics
    |> Enum.all?(&is_metric/1)
  end

  defp is_metric(metric) do
    if !Map.has_key?(@metrics, metric),
      do: raise ArgumentError, message: "Invalid metric #{inspect metric}. The parameter 'metrics' must be one of: #{inspect Map.keys(@default_metrics)}"
  end

  defp scopes_for(metrics) do
    metrics
    |> Enum.map(&(elem(@metrics[&1], 0)))
    |> Enum.uniq
  end
end
