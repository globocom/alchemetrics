defmodule Alchemetrics do
  alias Alchemetrics.Event
  alias Alchemetrics.Producer

  @default_options %{
    metadata: %{},
    metrics: [:last_interval],
  }

  def report(metric_name, value, options \\ %{}) do
    Map.merge(@default_options, options)
    |> Map.put(:name, metric_name)
    |> Map.put(:value, value)
    |> Event.create
    |> Producer.enqueue
  end

  defmacro report_time(metric_name, options, function_body) do
    quote do
      {total_time, result} = :timer.tc(fn -> unquote(function_body) |> Keyword.get(:do) end)
      report(unquote(metric_name), total_time, unquote(options))
      result
    end
  end

  def count(metric_name, %{metadata: metadata}) do
    report(metric_name, 1, %{metrics: [:total, :last_interval], metadata: metadata})
  end
end
