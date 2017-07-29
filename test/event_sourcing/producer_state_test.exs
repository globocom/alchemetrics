defmodule Alchemetrics.ProducerStateTest do
  use ExUnit.Case

  alias Alchemetrics.ProducerState
  alias Alchemetrics.Event

  @event Event.create(%{name: "some_event", metrics: [:p99]})
  @empty_state %ProducerState{}

  describe "#store_event" do
    test "adds a event to the event store" do
      assert @empty_state.event_store == {[], []}
      new_state = ProducerState.store_event(@empty_state, @event)
      assert new_state.event_store == {[@event], []}
    end
  end

  describe "#get_event" do
    test "returns {:empty, state} when the event store is empty" do
      assert ProducerState.get_event(@empty_state) == {:empty, @empty_state}
    end

    test "returns {event, state} when there was only one event on the store" do
      state = ProducerState.store_event(@empty_state, @event)
      assert ProducerState.get_event(state) == {@event, @empty_state}
    end

    test "returns {event, state} when there was two or more events on the store" do
      double_event_state =
        @empty_state
        |> ProducerState.store_event(@event)
        |> ProducerState.store_event(@event)

      single_event_state = ProducerState.get_event(double_event_state)
      assert single_event_state == {@event, %ProducerState{event_store: {[], [@event]}}}
      assert ProducerState.get_event(elem(single_event_state, 1)) == {@event, @empty_state}
    end
  end

  describe "#update_demand" do
    test "increments the producer's current demand by a given value" do
      assert @empty_state.demand == 0
      new_state = ProducerState.update_demand(@empty_state, 1)
      assert new_state.demand == 1
      new_state = ProducerState.update_demand(new_state, 10)
      assert new_state.demand == 11
    end

    test "accepts negative values as demand delta" do
      new_state = ProducerState.update_demand(@empty_state, -5)
      assert new_state.demand == -5
    end
  end
end
