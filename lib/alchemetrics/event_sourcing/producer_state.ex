defmodule Alchemetrics.ProducerState do
  defstruct [event_store: :queue.new, demand: 0]

  alias Alchemetrics.Event
  alias Alchemetrics.ProducerState

  def store_event(%ProducerState{} = old_state, %Event{} = event) do
    new_event_store = :queue.in(event, old_state.event_store)
    %ProducerState{old_state | event_store: new_event_store}
  end

  def get_event(%ProducerState{} = old_state) do
    case :queue.out(old_state.event_store) do
      {{:value, event}, event_store} ->
        {event, %ProducerState{old_state | event_store: event_store}}
      {:empty, event_store} ->
        {:empty, %ProducerState{old_state | event_store: event_store}}
    end
  end

  def update_demand(%ProducerState{} = old_state, demand_delta) do
    new_demand = old_state.demand+demand_delta
    %ProducerState{old_state | demand: new_demand}
  end
end
