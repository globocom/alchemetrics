defmodule Alchemetrics.Metric do
  @enforce_keys [:scope, :name, :value]
  defstruct [:scope, :name, :value, :user_data, report_interval: 10_000]

  def from_event(%Alchemetrics.Event{} = event) do
    %Alchemetrics.Metric{name: format_name(event), scope: event.action |> to_scope, value: event.value, user_data: user_data()}
  end

  defp format_name(%Alchemetrics.Event{} = event), do: [event.type, event.metric, event.action |> to_scope |> to_string]

  defp user_data do
    case Application.get_env(:alchemetrics, :user_data, []) do
      [] ->
        nil
      user_data when is_list(user_data) ->
        Enum.into(user_data, %{})
      user_data ->
        raise ArgumentError, message: "Invalid parameter 'user_data' #{inspect user_data}. Must be a KeywordList"
    end
  end

  defp to_scope(action) do
    case action do
      :count -> :spiral
      :measure_time -> :histogram
    end
  end
end
