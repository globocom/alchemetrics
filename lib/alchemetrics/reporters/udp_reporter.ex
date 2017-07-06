defmodule Alchemetrics.UDPReporter do
  @moduledoc false

  @behaviour :exometer_report
  require Logger

  def exometer_init(opts) do
    case :gen_udp.open(0) do
      {:ok, sock} ->
        Logger.debug("Starting collect metrics")
        {:ok, %{socket: sock, hostname: opts[:hostname], port: opts[:port]}}
      {:error, _} = error ->
        Logger.error "#{inspect error}"
        error
    end
  end

  def exometer_report(metric, data_point, _extra, value, state) do
    data = default_data(data_point, value)
    |> Map.merge(metric_data(metric))
    |> Map.merge(user_extra_data(metric))

    case :gen_udp.send(state[:socket], String.to_char_list(state[:hostname]), state[:port], Poison.encode!(data)) do
      :ok ->
        Logger.debug("Reporting to #{state[:hostname]}:#{state[:port]} => #{inspect data}")
        {:ok, state}
      {:error, reason} ->
        Logger.error("Unable to write metric. #{reason}")
        {:ok, state}
    end
  end

  def user_extra_data(_metric) do
    %{}
  end

  defp metric_data(["controller" = type, name, scope]) do
    %{
      "type": type,
      "name": name |> to_string |> String.replace("/", "."),
      "scope": scope
    }
  end

  defp metric_data([type, name, scope]) do
    %{
      "type": type,
      "name": name,
      "scope": scope
    }
  end

  defp metric_data([name, scope]) do
    %{
      "name": name,
      "scope": scope
    }
  end

  defp default_data(data_point, value) do
    %{
      "client": Application.get_env(:alchemetrics, :app_name),
      "owner": Application.get_env(:alchemetrics, :owner),
      "data_point": data_point |> format_data_point,
      "value": value,
      "timestamp": :os.system_time(:milli_seconds),
      "ip": get_node_ip()
    }
  end

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

  # Public function that should be implemented according to
  # https://github.com/Feuerlabs/exometer_core/blob/master/src/exometer_report_tty.erl
  def exometer_subscribe(_, _, _, _, opts), do: {:ok, opts}
  def exometer_unsubscribe(_, _, _, opts), do: {:ok, opts}
  def exometer_call(_, _, opts), do: {:ok, opts}
  def exometer_cast(_, opts), do: {:ok, opts}
  def exometer_info(_, opts), do: {:ok, opts}
  def exometer_newentry(_, opts), do: {:ok, opts}
  def exometer_setopts(_, _, _, opts), do: {:ok, opts}
  def exometer_terminate(_, _), do: nil
end
