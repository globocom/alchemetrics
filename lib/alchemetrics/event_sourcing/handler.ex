defmodule Alchemetrics.Handler do
  alias Alchemetrics.Event
  alias Alchemetrics.Exometer
  alias Alchemetrics.Exometer.Metric

  def start_link(%Event{} = event) do
    Task.start_link(fn ->
      Metric.from_event(event)
      |> Enum.each(&Exometer.update/1)
    end)
  end
end
