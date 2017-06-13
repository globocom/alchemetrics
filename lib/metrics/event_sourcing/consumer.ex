defmodule ElixirMetrics.Consumer do
  use ConsumerSupervisor

  def start_link() do
    children = [
      worker(ElixirMetrics.Handler, [], restart: :temporary)
    ]

    ConsumerSupervisor.start_link(
      children, strategy: :one_for_one,
      subscribe_to: [{ElixirMetrics.Producer, max_demand: 150}]
    )
  end
end
