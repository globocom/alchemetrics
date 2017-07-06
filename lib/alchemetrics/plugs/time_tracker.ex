defmodule Alchemetrics.Plugs.TimeTracker do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    req_start_time = :erlang.monotonic_time(:micro_seconds)
    conn
    |> assign(:request_start_time, req_start_time)
  end
end
