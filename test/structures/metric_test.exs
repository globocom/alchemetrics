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

  describe "#metric_from_scope" do
    test "returns nil if scope is not valid" do
      assert is_nil(Metric.metric_from_scope(:invalid, 99))
      assert is_nil(Metric.metric_from_scope(:invalid, 95))
      assert is_nil(Metric.metric_from_scope(:invalid, :mean))
      assert is_nil(Metric.metric_from_scope(:invalid, :count))
      assert is_nil(Metric.metric_from_scope(:invalid, :one))
    end

    test "returns nil if datapoint is not valid" do
      assert is_nil(Metric.metric_from_scope(:spiral, :invalid))
      assert is_nil(Metric.metric_from_scope(:histogram, :invalid))
    end

    test "returns the equivalent metric given the exometer datapoint and scope" do
      assert Metric.metric_from_scope(:histogram, 99) == :p99
      assert Metric.metric_from_scope(:histogram, 95) == :p95
      assert Metric.metric_from_scope(:histogram, :mean) == :avg
      assert Metric.metric_from_scope(:spiral, :count) == :total
      assert Metric.metric_from_scope(:spiral, :one) == :last_interval
    end
  end
end
