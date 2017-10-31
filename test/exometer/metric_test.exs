defmodule Alchemetrics.MetricTest do
  use ExUnit.Case

  alias Alchemetrics.Event
  alias Alchemetrics.Exometer.Metric

  @allowed_metrics [:avg, :last_interval, :max, :min, :p95, :p99, :total]

  describe "#from_event" do
    test "raises ArgumentError if the user provides an invalid metric" do
      metric_name = :invalid_metric

      assert_raise ArgumentError, fn ->
        Event.create(%{datapoints: [metric_name], value: 1})
        |> Metric.from_event
      end
    end

    test "creates an exometer metric of the :histogram type if datapoints are :p99, :p95 or :avg" do
      metrics_array = Event.create(%{datapoints: [:p99, :p95, :avg], value: 1})
      |> Metric.from_event
      assert length(metrics_array) == 1
      assert List.first(metrics_array).scope == :histogram
    end

    test "creates an exometer metric of the :spiral type if datapoints are :last_interval or :total" do
      metrics_array = Event.create(%{datapoints: [:last_interval, :total], value: 1})
      |> Metric.from_event
      assert length(metrics_array) == 1
      assert List.first(metrics_array).scope == :spiral
    end

    test "creates an array with spiral and histogram datapoints if event has mixed types of datapoints" do
      metrics_array = Event.create(%{datapoints: @allowed_metrics, value: 1})
      |> Metric.from_event
      assert length(metrics_array) == 2
      assert List.first(metrics_array).scope == :histogram
      assert List.last(metrics_array).scope == :spiral
    end

    @metadata [type: :request, controller: "controller_name", action: "action_name"]
    test "creates a metric in which its name is the union of scope and metadata" do
      {histogram, spiral} = Event.create(%{datapoints: @allowed_metrics, value: 1, metadata: @metadata})
      |> Metric.from_event
      |> List.to_tuple
      
      assert histogram.name == [:histogram, @metadata]
      assert spiral.name == [:spiral, @metadata]
    end
  end
end
