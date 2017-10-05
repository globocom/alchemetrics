defmodule Alchemetrics.BackendStarter do
  @moduledoc false

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    backends = Application.get_env :alchemetrics, :backends, []
    backends
    |> Enum.each(fn({module, init_options}) ->
      :exometer_report.add_reporter(module, init_options)
    end)
    {:ok, :added}
  end

  def start_reporter(module, init_options), do: GenServer.cast(__MODULE__, {:add_reporter, [module: module, init_options: init_options]})

  def handle_cast({:add_reporter, [module: module, init_options: init_options]}, state) do
    :exometer_report.add_reporter(module, init_options)
    {:noreply, state}
  end
end
