defmodule Alchemetrics.Handler do
  alias Alchemetrics.Event
  alias Alchemetrics.Metric
  alias Alchemetrics.MetricBackend

  def start_link(%Event{} = event) do
    Task.start_link(fn ->
      Metric.from_event(event)
      |> MetricBackend.update
    end)
  end
end
