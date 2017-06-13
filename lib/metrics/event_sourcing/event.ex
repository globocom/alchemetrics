defmodule ElixirMetrics.Event do
  @enforce_keys [:name, :type, :scope]
  defstruct [metric: nil, type: nil, action: nil, value: 1, default_data: %{}]

  def create(opts \\ %{}) do
    struct(__MODULE__, opts)
  end
end
