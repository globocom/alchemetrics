defmodule Alchemetrics.EventTest do
  use ExUnit.Case

  alias Alchemetrics.Event

  describe "#create" do
    test "name and datapoints must be defined" do
      event = Event.create(%{value: 1, datapoints: [:p99]})
      assert event.datapoints == [:p99]
      assert event.metadata == []
    end

    test "sets metadata as an empty map if no metadata is provided" do
      event = Event.create(%{value: 1, datapoints: [:p99]})
      assert event.metadata == []
    end

    test "raise ArgumentError if the is not provided" do
      assert_raise ArgumentError, fn ->
        Event.create(%{datapoints: [:p99]})
      end
    end

    test "raise ArgumentError if the name is not a string" do
      assert_raise ArgumentError, fn ->
        Event.create(%{name: 1, datapoints: [:p99]})
      end
    end

    test "raise ArgumentError if the datapoints list is not provided" do
      assert_raise ArgumentError, fn ->
        Event.create(%{value: 1})
      end
    end

    test "raise ArgumentError if the datapoints list is not a atom list" do
      assert_raise ArgumentError, fn ->
        Event.create(%{value: 1, datapoints: "some_invalid_metric"})
      end
    end

    test "raise ArgumentError if the value is not a number" do
      assert_raise ArgumentError, fn ->
        Event.create(%{value: 1, datapoints: [:p99], value: "one"})
      end
    end

    test "raise ArgumentError if metadata is not a keyword list" do
      assert_raise ArgumentError, fn ->
        Event.create(%{value: 1, datapoints: [:p99], metadata: %{invalid: true}})
      end
    end
  end
end
