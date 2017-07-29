defmodule Alchemetrics.Event do
  @enforce_keys [:name, :metrics]
  defstruct [:name, :metrics, :value, metadata: %{}]

  @defaults %{value: 1}

  def create(opts \\ %{}) do
    opts = Map.merge(@defaults, opts)

    validate_name(opts[:name])
    validate_metrics(opts[:metrics])
    validate_metadata(opts[:metadata])
    validate_value(opts[:value])

    struct(__MODULE__, opts)
  end

  defp validate_name(name) when is_bitstring(name), do: :ok
  defp validate_name(name), do: raise ArgumentError, message: "Invalid name #{inspect name}. Must be a string"

  defp validate_metrics(metrics) when is_list(metrics), do: :ok
  defp validate_metrics(metrics), do: raise ArgumentError, message: "Invalid metric list #{inspect metrics}. Must be a list of atoms"

  defp validate_metadata(metadata) when is_map(metadata) or is_nil(metadata), do: :ok
  defp validate_metadata(metadata), do: raise ArgumentError, message: "Invalid metadata #{inspect metadata}. Must be a map"

  defp validate_value(value) when is_number(value), do: :ok
  defp validate_value(value), do: raise ArgumentError, message: "Invalid value #{inspect value}. Must be a number"
end
