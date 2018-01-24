defmodule Alchemetrics.MetricData do
  import Map

  def build(metadata, data_point, value, options) do
    initial_map()
    |> put(:value, value)
    |> put(:data_point, data_point |> format_data_point)
    |> merge(options |> Enum.into(%{}))
    |> merge(metadata |> Enum.into(%{}))
  end

  defp initial_map, do: %{
    "timestamp": :os.system_time(:milli_seconds),
    "ip": get_node_ip(),
    "hostname": :inet.gethostname |> elem(1) |> to_string
  }

  defp format_data_point(data_point) when is_number(data_point), do: Integer.to_string(data_point)
  defp format_data_point(data_point), do: data_point

  defp get_node_ip do
    :inet.getif
    |> elem(1)
    |> List.first
    |> elem(0)
    |> Tuple.to_list
    |> Enum.join(".")
  end
end
