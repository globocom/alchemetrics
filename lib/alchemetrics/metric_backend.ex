defmodule Alchemetrics.MetricBackend do
  def update(%Alchemetrics.Metric{} = metric) do
    ensure_created_and_subscribed(metric)
    :exometer.update(metric.name, metric.value)
  end

  defp ensure_created_and_subscribed(%Alchemetrics.Metric{} = metric) do
    if(metric_undefined?(metric)) do
      create(metric)
      ensure_subscribed(metric)
    end
  end

  defp create(%Alchemetrics.Metric{} = metric) do
    :exometer.new(metric.name, metric.scope, [time_span: metric.report_interval])
  end

  defp ensure_subscribed(%Alchemetrics.Metric{} = metric) do
    reporters = :exometer_report.list_reporters
    report_interval = Application.get_env(:alchemetrics, :report_interval) || metric.report_interval
    datapoints = metric_datapoints(metric)

    Enum.each(reporters, fn({reporter, _}) ->
      :exometer_report.subscribe(reporter, metric.name, datapoints, report_interval)
    end)
  end

  defp metric_undefined?(%Alchemetrics.Metric{} = metric) do
    case :exometer.info(metric.name) do
      :undefined -> true
      _ -> false
    end
  end

  defp metric_datapoints(%Alchemetrics.Metric{} = metric) do
    metric.name
    |> :exometer.info(:datapoints)
  end
end
