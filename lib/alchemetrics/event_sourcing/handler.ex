defmodule Alchemetrics.Handler do
  alias Alchemetrics.Event
  alias Alchemetrics.Metric
  alias Alchemetrics.MetricBackend

  def start_link(%Event{} = event) do
    Task.start_link(fn ->
      Metric.from_event(event)
      |> Enum.each(&MetricBackend.update/1)
    end)
  end
end
