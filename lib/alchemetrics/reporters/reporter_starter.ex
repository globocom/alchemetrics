defmodule Alchemetrics.ReporterStarter do
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    reporter_list = Application.get_env :alchemetrics, :reporter_list, []
    reporter_list
    |> Enum.each(fn(reporter) ->
      :exometer_report.add_reporter(reporter[:module], reporter[:opts])
    end)
    {:ok, :added}
  end

  def start_reporter(module, opts), do: GenServer.cast(__MODULE__, {:add_reporter, [module: module, opts: opts]})

  def handle_cast({:add_reporter, [module: module, opts: opts]}, state) do
    :exometer_report.add_reporter(module, opts)
    {:noreply, state}
  end
end
