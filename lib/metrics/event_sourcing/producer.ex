defmodule Metrics.Producer do
  use GenStage

  alias Metrics.ProducerState

  def start_link(name \\ __MODULE__), do: GenStage.start_link(name, %ProducerState{}, name: name)

  def init(%ProducerState{} = initial_state), do: {:producer, initial_state}

  def enqueue(name \\ __MODULE__, %Metrics.Event{} = event), do: GenStage.cast(name, {:enqueue, event})

  def handle_cast({:enqueue, event}, %ProducerState{} = state) do
    state
    |> store_event(event)
  end

  def handle_demand(incoming_demand, %ProducerState{} = state) do
    state
    |> change_demand_by(incoming_demand)
  end

  defp store_event(%ProducerState{} = state, event) do
    state
    |> ProducerState.store_event(event)
    |> dispatch_events
  end

  defp change_demand_by(%ProducerState{} = state, demand_delta) when is_integer(demand_delta) do
    state
    |> ProducerState.update_demand(demand_delta)
    |> dispatch_events
  end

  defp dispatch_events(state, event_list \\ [])
  defp dispatch_events(%ProducerState{demand: 0} = state, event_list), do: {:noreply, event_list, state}
  defp dispatch_events(%ProducerState{} = state, event_list) do
    case state |> ProducerState.get_event() do
      {:empty, new_state} ->
        {:noreply, event_list, new_state}
      {event, new_state} ->
        new_event_list = [event|event_list]
        dispatch_events(new_state, new_event_list)
    end
  end
end
