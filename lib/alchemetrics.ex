defmodule Alchemetrics do
  alias Alchemetrics.Event
  alias Alchemetrics.Producer

  def report(value, metadata) do
    create_event(value, metadata, Alchemetrics.Exometer.Datapoints.histogram)
    |> Producer.enqueue
  end

  def increment_by(value, metadata) do
    create_event(value, metadata, Alchemetrics.Exometer.Datapoints.spiral)
    |> Producer.enqueue
  end

  def increment(metadata), do: increment_by(1, metadata)

  defp create_event(value, metadata, datapoints) do
    %{}
    |> Map.put(:metadata, metadata)
    |> Map.put(:datapoints, datapoints)
    |> Map.put(:value, value)
    |> Event.create
  end
end
