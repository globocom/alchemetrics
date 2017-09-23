defmodule Alchemetrics.Exometer.Metric do
  @moduledoc false

  alias Alchemetrics.Exometer.Datapoints

  @enforce_keys [:scope, :name, :value]

  defstruct [:scope, :datapoints, :name, :value, metadata: %{}]

  def from_event(%Alchemetrics.Event{datapoints: datapoints, value: value, metadata: metadata}) do
    Datapoints.validate(datapoints)
    transformed_metadata = metadata |> Enum.into([])

    datapoints
    |> Datapoints.scopes_for
    |> Enum.map(fn scope ->
      name = [scope, transformed_metadata]
      %Alchemetrics.Exometer.Metric{
        name: name,
        datapoints: Datapoints.to_exometer(scope, datapoints),
        scope: scope,
        value: value,
        metadata: metadata
      }
    end)
  end
end
