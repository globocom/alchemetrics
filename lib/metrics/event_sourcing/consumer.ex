defmodule Metrics.Consumer do
  use ConsumerSupervisor

  def start_link() do
    children = [
      worker(Metrics.Handler, [], restart: :temporary)
    ]

    ConsumerSupervisor.start_link(
      children, strategy: :one_for_one,
      subscribe_to: [{Metrics.Producer, max_demand: 150}]
    )
  end
end
