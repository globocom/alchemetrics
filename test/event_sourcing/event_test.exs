defmodule Alchemetrics.EventTest do
  use ExUnit.Case

  alias Alchemetrics.Event

  describe "#create" do
    test "name and metrics must be defined" do
      event = Event.create(%{name: "some_event", metrics: [:p99]})
      assert event.name == "some_event"
      assert event.metrics == [:p99]
      assert event.metadata == %{}
    end

    test "sets value as 1 if no value is provided" do
      event = Event.create(%{name: "some_event", metrics: [:p99]})
      assert event.value == 1
    end

    test "sets metadata as an empty map if no metadata is provided" do
      event = Event.create(%{name: "some_event", metrics: [:p99]})
      assert event.metadata == %{}
    end

    test "raise ArgumentError if the name is not provided" do
      assert_raise ArgumentError, fn ->
        Event.create(%{metrics: [:p99]})
      end
    end

    test "raise ArgumentError if the name is not a string" do
      assert_raise ArgumentError, fn ->
        Event.create(%{name: 1, metrics: [:p99]})
      end
    end

    test "raise ArgumentError if the metrics list is not provided" do
      assert_raise ArgumentError, fn ->
        Event.create(%{name: "some_event"})
      end
    end

    test "raise ArgumentError if the metrics list is not a atom list" do
      assert_raise ArgumentError, fn ->
        Event.create(%{name: "some_event", metrics: "some_invalid_metric"})
      end
    end
  end
end
