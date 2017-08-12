defmodule Alchemetrics.Handler do
  alias Alchemetrics.Event
  alias Alchemetrics.Metric
  alias Alchemetrics.Exometer

  def start_link(%Event{} = event) do
    Task.start_link(fn ->
      Metric.from_event(event)
      |> Enum.each(&Exometer.update/1)
    end)
  end
end
