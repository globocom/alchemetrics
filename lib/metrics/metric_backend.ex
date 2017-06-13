defmodule Metrics.MetricBackend do
  def update(%Metrics.Metric{} = metric) do
    ensure_created_and_subscribed(metric)
    :exometer.update(metric.name, metric.value)
  end

  defp ensure_created_and_subscribed(%Metrics.Metric{} = metric) do
    if(metric_undefined?(metric)) do
      create(metric)
      ensure_subscribed(metric)
    end
  end

  defp create(%Metrics.Metric{} = metric) do
    :exometer.new(metric.name, metric.scope, [time_span: metric.report_interval])
  end

  defp ensure_subscribed(%Metrics.Metric{} = metric) do
    reporters = :exometer_report.list_reporters
    report_interval = Application.get_env(:metrics, :report_interval) || metric.report_interval
    datapoints = metric_datapoints(metric)

    Enum.each(reporters, fn({reporter, _}) ->
      :exometer_report.subscribe(reporter, metric.name, datapoints, report_interval)
    end)
  end

  defp metric_undefined?(%Metrics.Metric{} = metric) do
    case :exometer.info(metric.name) do
      :undefined -> true
      _ -> false
    end
  end

  defp metric_datapoints(%Metrics.Metric{} = metric) do
    metric.name
    |> :exometer.info(:datapoints)
  end
end
