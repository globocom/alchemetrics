defmodule Alchemetrics.MetricTest do
  use ExUnit.Case

  alias Alchemetrics.Event
  alias Alchemetrics.Metric

  @allowed_metrics [:avg, :last_interval, :p95, :p99, :total]

  describe "#from_event" do
    test "raises ArgumentError if the user provides an invalid metric" do
      metric_name = :invalid_metric
      message = "Invalid metric #{inspect metric_name}. The parameter 'metrics' must be one of: #{inspect @allowed_metrics}"

      assert_raise ArgumentError, message, fn ->
        Event.create(%{name: "some_event", metrics: [metric_name]})
        |> Metric.from_event
      end
    end

    test "creates an exometer metric of the :histogram type if metrics are :p99, :p95 or :avg" do
      metrics_array = Event.create(%{name: "some_event", metrics: [:p99, :p95, :avg]})
      |> Metric.from_event
      assert length(metrics_array) == 1
      assert List.first(metrics_array).scope == :histogram
    end

    test "creates an exometer metric of the :spiral type if metrics are :last_interval or :total" do
      metrics_array = Event.create(%{name: "some_event", metrics: [:last_interval, :total]})
      |> Metric.from_event
      assert length(metrics_array) == 1
      assert List.first(metrics_array).scope == :spiral
    end

    test "creates an array with spiral and histogram metrics if event has mixed types of metrics" do
      metrics_array = Event.create(%{name: "some_event", metrics: @allowed_metrics})
      |> Metric.from_event
      assert length(metrics_array) == 2
      assert List.first(metrics_array).scope == :histogram
      assert List.last(metrics_array).scope == :spiral
    end
  end
end
