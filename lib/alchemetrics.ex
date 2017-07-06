defmodule Alchemetrics do
  alias Alchemetrics.Event
  alias Alchemetrics.Producer

  def count(type, metric) when is_bitstring(type) and is_bitstring(metric) do
    Event.create(%{type: type, metric: metric, action: :count})
    |> Producer.enqueue
  end
  def count(_type, _metric), do: raise ArgumentError, message: "Arguments 'metric' and 'type' must be strings"

  def measure_time(type, metric, value) when is_bitstring(type) and is_bitstring(metric) do
    Event.create(%{type: type, metric: metric, action: :measure_time, value: value})
    |> Producer.enqueue
  end
  def measure_time(_type, _metric), do: raise ArgumentError, message: "Arguments 'metric' and 'type' must be strings"

  def instrument_function(type, metric, function) when is_bitstring(type) and is_bitstring(metric) do
    {total_time, result} = :timer.tc(fn -> function.() end)
    count(type, metric)
    measure_time(type, metric, total_time)
    result
  end
  def instrument_function(_type, _metric, _functions), do: raise ArgumentError, message: "Arguments 'metric' and 'type' must be strings"
end
