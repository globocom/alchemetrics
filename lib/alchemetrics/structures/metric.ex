defmodule Alchemetrics.Metric do

  @metrics %{
    p99: {:histogram, 99},
    p95: {:histogram, 95},
    avg: {:histogram, :mean},
    total: {:spiral, :count},
    last_interval: {:spiral, :one},
  }

  @enforce_keys [:scope, :name, :value]

  defstruct [:scope, :datapoints, :name, :value, metadata: %{}]

  def from_event(%Alchemetrics.Event{name: name, metrics: metrics, value: value, metadata: metadata} = event) do
    validate_metrics(metrics)

    metrics
    |> scopes_for
    |> Enum.map(fn scope ->
      %Alchemetrics.Metric{name: [name, scope], datapoints: datapoints_for(scope, metrics), scope: scope, value: value, metadata: metadata}
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
    |> check_valid_metrics
  end

  defp check_valid_metrics(true), do: nil
  defp check_valid_metrics(false),
    do: raise "'metrics' parameter must be one of: #{inspect Map.keys(@metrics)}"

  defp is_metric(metric) do
    Map.has_key?(@metrics, metric)
  end

  defp scopes_for(metrics) do
    metrics
    |> Enum.map(&(elem(@metrics[&1], 0)))
    |> Enum.uniq
  end

end
