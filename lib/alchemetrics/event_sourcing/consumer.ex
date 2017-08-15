defmodule Alchemetrics.Consumer do
  use ConsumerSupervisor

  def init(args), do: {:consumer, args}

  def start_link() do
    children = [
      worker(Alchemetrics.Handler, [], restart: :temporary)
    ]

    ConsumerSupervisor.start_link(
      children, strategy: :one_for_one,
      subscribe_to: [{Alchemetrics.Producer, max_demand: 150}]
    )
  end
end
