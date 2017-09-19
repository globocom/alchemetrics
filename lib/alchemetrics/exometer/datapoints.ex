defmodule Alchemetrics.Exometer.Datapoints do
  @default_datapoints %{
    p99: {:histogram, 99},
    p95: {:histogram, 95},
    avg: {:histogram, :mean},
    min: {:histogram, :min},
    max: {:histogram, :max},
    total: {:spiral, :count},
    last_interval: {:spiral, :one}
  }

  @erlang_datapoints %{
    memory_atom: {:memory, :atom},
    memory_binary: {:memory, :binary},
    memory_ets: {:memory, :ets},
    memory_processes: {:memory, :processes},
    memory_total: {:memory, :total},
    statistics_runqueue: {:statistics, :run_queue}
  }

  @datapoints Map.merge(@default_datapoints, @erlang_datapoints)

  def spiral, do: [:last_interval, :total]
  def histogram, do: [:p99, :p95, :avg, :min, :max] ++ spiral

  def from_scope(scope, datapoint) do
    case Enum.find(@datapoints, fn({_, d}) -> d == {scope, datapoint} end) do
      nil -> nil
      {metric, _} -> metric
      _ -> nil
    end
  end

  def to_exometer(scope, datapoints) do
    @datapoints
    |> Enum.filter(fn({datapoint, {metric_scope, _}})->
      scope == metric_scope && Enum.member?(datapoints, datapoint)
    end)
    |> Enum.map(fn({_, {_, exometer_datapoint}})->
      exometer_datapoint
    end)
  end

  def scopes_for(datapoints) do
    datapoints
    |> Enum.map(&(elem(@datapoints[&1], 0)))
    |> Enum.uniq
  end

  def validate(datapoint_list) do
    Enum.each(datapoint_list, fn(datapoint) ->
      if !Map.has_key?(@datapoints, datapoint),
        do: raise ArgumentError, message: "Invalid metric #{inspect datapoint}. The parameter 'datapoints' must be one of: #{inspect Map.keys(@default_datapoints)}"
    end)
  end

  defp is_metric(metric) do
    if !Map.has_key?(@datapoints, metric),
      do: raise ArgumentError, message: "Invalid metric #{inspect metric}. The parameter 'datapoints' must be one of: #{inspect Map.keys(@default_datapoints)}"
  end
end
