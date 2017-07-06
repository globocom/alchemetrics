defmodule Alchemetrics.Metric do

  @metrics %{
    p99: {:histogram, 99},
    p95: {:histogram, 95},
    avg: {:histogram, :mean},
    total: {:spiral, :count},
    last_interval: {:spiral, :one},
  }

  @enforce_keys [:scope, :name, :value]

  defstruct [:scope, :datapoints, :name, :value, custom_data: %{}, metadata: %{}]

  def from_event(%Alchemetrics.Event{name: name, metrics: metrics, value: value, metadata: metadata} = event) do
    validate_metrics(metrics)

    metrics
    |> scopes_for
    |> Enum.map(fn scope ->
      %Alchemetrics.Metric{name: [name, scope], datapoints: datapoints_for(scope, metrics), scope: scope, value: value, custom_data: custom_data(), metadata: metadata}
    end)
  end

  defp datapoints_for(scope, metrics) do
    @metrics
    |> Enum.filter(fn {metric, {metric_scope, _}} -> scope == metric_scope && Enum.member?(metrics, metric) end)
    |> Enum.map(fn {_, {_, datapoint}} -> datapoint end)
  end

  defp custom_data do
    case Application.get_env(:alchemetrics, :custom_data, %{}) do
      data when is_list(data) ->
        Enum.into(data, %{})
      data when is_map(data) -> data
      data ->
        raise ArgumentError, message: "Invalid parameter 'custom_data' #{inspect data}. Must be a KeywordList"
    end
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
