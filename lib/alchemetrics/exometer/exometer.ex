defmodule Alchemetrics.Exometer do
  @default_report_interval 10_000

  def update(%Alchemetrics.Exometer.Metric{name: name, value: value} = metric) do
    ensure_created_and_subscribed(metric)
    :exometer.update(name, value)
  end

  def ensure_created_and_subscribed(%Alchemetrics.Exometer.Metric{name: name, scope: _scope} = metric) do
    if(metric_undefined?(name)) do
      create(metric)
      ensure_subscribed(metric)
    end
  end

  defp create(%Alchemetrics.Exometer.Metric{} = metric) do
    try do
      :exometer.new(metric.name, metric.scope, [time_span: report_interval(), __alchemetrics__: %{metadata: metric.metadata}])
    rescue
      ErlangError -> :ok
    end
  end

  defp ensure_subscribed(%Alchemetrics.Exometer.Metric{name: name, datapoints: datapoints}) do
    reporters = :exometer_report.list_reporters

    Enum.each(reporters, fn({reporter, _}) ->
      :exometer_report.subscribe(reporter, name, datapoints, report_interval())
    end)
  end

  defp metric_undefined?(name) do
    case :exometer.info(name) do
      :undefined -> true
      _ -> false
    end
  end

  defp report_interval do
    Application.get_env(:alchemetrics, :report_interval) || @default_report_interval
  end
end
