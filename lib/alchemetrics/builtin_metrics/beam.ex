defmodule Alchemetrics.BuiltinMetrics.Beam do
  alias Alchemetrics.Exometer

  @memory_datapoints ~w(atom binary ets processes total)a
  @erlang_memory_metric %Alchemetrics.Exometer.Metric{
    name: ~w(beam memory)a,
    scope: {:function, :erlang, :memory, [], :proplist, @memory_datapoints},
    datapoints: @memory_datapoints,
    value: nil
  }

  @erlang_statistics_metric %Alchemetrics.Exometer.Metric{
    name: ~w(beam statistics)a,
    scope: {:function, :erlang, :statistics, [:'$dp'], :value, [:run_queue]},
    datapoints: [:run_queue],
    value: nil
  }

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Exometer.ensure_created_and_subscribed @erlang_memory_metric
    Exometer.ensure_created_and_subscribed @erlang_statistics_metric
    {:ok, :added}
  end
end
