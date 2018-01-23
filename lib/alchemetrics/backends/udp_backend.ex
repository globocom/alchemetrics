defmodule Alchemetrics.UDPBackend do
  use Alchemetrics.CustomBackend
  alias Alchemetrics.UDP
  alias Alchemetrics.MetricData
  require Logger

  def init(options) do
    case UDP.open do
      {:ok, sock} ->
        Logger.info "UDP Reporter initialized"
        {:ok, %{socket: sock, hostname: options[:hostname], port: options[:port]}}
      {:error, _error_message} = error ->
        Logger.warn "#{inspect error}"
        error
    end
  end

  def report(metadata, datapoint, value, options) do
    metadata 
    |> MetricData.build(datapoint, value, options) 
    |> :erlang.term_to_binary
    |> send_metric(options)
  end

  defp send_metric(data, options) do
    {sock, host, port} = extract_options(options)

    UDP.send(sock, host, port, data)
    |> case do
      :ok -> nil
      {:error, reason} -> Logger.error "Error while sending metric: #{reason}"
    end
  end

  defp extract_options(opts) do
    hostname = String.to_charlist(opts[:hostname])
    {opts[:socket], hostname, opts[:port]}
  end
end
