defmodule ElixirMetrics.Handler do
  alias ElixirMetrics.Event
  alias ElixirMetrics.Metric
  alias ElixirMetrics.MetricBackend

  def start_link(%Event{} = event) do
    Task.start_link(fn ->
      Metric.from_event(event)
      |> MetricBackend.update
    end)
  end
end
