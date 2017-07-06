defmodule Alchemetrics.Event do
  @enforce_keys [:name, :metrics]
  defstruct [:name, :metrics, value: 1, metadata: %{}]

  def create(opts \\ %{}) do
    struct(__MODULE__, opts)
  end
end
