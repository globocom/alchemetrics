defmodule Metrics.Handler do
  alias Metrics.Event
  alias Metrics.Metric
  alias Metrics.MetricBackend

  def start_link(%Event{} = event) do
    Task.start_link(fn ->
      Metric.from_event(event)
      |> MetricBackend.update
    end)
  end
end
