defmodule ElixirMetrics.Plugs.RequestMetrics do
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _config) do
    Plug.Conn.register_before_send conn, fn conn ->
      request_duration = calculate_total_request_time(conn)

      ElixirMetrics.count("controller", metric_name_for(conn))
      ElixirMetrics.measure_time("controller", metric_name_for(conn), request_duration)

      conn
    end
  end

  defp calculate_total_request_time(conn) do
    case conn.assigns[:request_start_time] do
      nil -> 0
      req_start_time -> :erlang.monotonic_time(:micro_seconds) - req_start_time
    end
  end

  defp metric_name_for(conn) do
    controller = Phoenix.Controller.controller_module conn
    "#{standardize_controller_name(controller)}/#{Phoenix.Controller.action_name conn}"
  end

  defp standardize_controller_name(controller) do
    controller
    |> Macro.underscore
    |> String.split("/")
    |> List.last
  end
end
