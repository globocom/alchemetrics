defmodule Alchemetrics do
  alias Alchemetrics.Event
  alias Alchemetrics.Producer

  @default_options %{
    metadata: %{},
    metrics: [:last_interval],
  }

  def report(metric_name, value, options \\ %{}) when is_bitstring(metric_name) and is_number(value) and is_map(options) do
    %{metadata: metadata, metrics: metrics} = Map.merge(@default_options, options)
    Event.create(%{name: metric_name, value: value, metrics: metrics, metadata: metadata})
    |> Producer.enqueue
  end
  def report(_metric_name, _value, _options), do: raise ArgumentError, message: "'metric_name' must be string and 'value' must be number or function"

  defmacro report_time(metric_name, options, function_body) when is_bitstring(metric_name) do
    quote do
      {total_time, result} = :timer.tc(fn -> unquote(function_body) |> Keyword.get(:do) end)
      report(unquote(metric_name), total_time, unquote(options))
      result
    end
  end

  def count(metric_name, %{metadata: metadata}) when is_bitstring(metric_name) do
    report(metric_name, 1, %{metrics: [:total, :last_interval], metadata: metadata})
  end
  def count(_metric_name, _options), do: raise ArgumentError, message: "'metric_name' must be string"
end
