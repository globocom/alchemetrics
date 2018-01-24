defmodule Alchemetrics.UDPTest do
  use ExUnit.Case
  import Mock
  alias Alchemetrics.UDP
  alias Alchemetrics.UDPBackend, as: UDPReporter
  
  @fake_socket_handler 10
  defp success, do: fn -> {:ok, @fake_socket_handler} end
  @fake_error_message "udp socket is unavailable"
  defp fail, do: fn -> {:error, @fake_error_message} end

  test_with_mock "when udp is available, it returns a tuple with :ok and the socket handler", UDP, [open: success()] do
    assert {:ok, reporter_options} = UDPReporter.init %{hostname: "fake_url", port: 1024}
    assert reporter_options[:socket] == @fake_socket_handler
    assert reporter_options[:hostname] == "fake_url"
    assert reporter_options[:port] == 1024
  end

  test_with_mock "when udp is unavailable, it returns a tuple with error message", UDP, [open: fail()] do
    assert {:error, error_message} = UDPReporter.init %{hostname: "", port: 0}
    assert error_message == @fake_error_message
  end


end
