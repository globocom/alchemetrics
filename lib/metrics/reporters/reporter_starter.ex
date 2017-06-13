defmodule Metrics.ReporterStarter do
  use GenStage
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    reporter_list = Application.get_env :metrics, :reporter_list, []
    reporter_list
    |> Enum.each(fn(reporter) ->
      :exometer_report.add_reporter(reporter[:module], reporter[:opts])
    end)
    {:ok, :added}
  end

  def handle_cast({:add_reporter, [module: module, opts: opts]}) do
    :exometer_report.add_reporter(module, opts)
  end
end
