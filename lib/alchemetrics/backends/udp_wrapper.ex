defmodule Alchemetrics.UDP do
  def open, do: :gen_udp.open(0)

  def send(sock, hostname, port, data) do 
    :gen_udp.send(sock, hostname, port, data)
  end
end
