defmodule Alchemetrics.Event do
  @moduledoc false

  defstruct [:datapoints, :value, metadata: []]

  def create(opts \\ %{}) do
    validate_metrics(opts[:datapoints])
    validate_metadata(opts[:metadata])
    validate_value(opts[:value])

    struct(__MODULE__, opts)
  end

  defp validate_metrics(datapoints) when is_list(datapoints), do: :ok
  defp validate_metrics(datapoints), do: raise ArgumentError, message: "Invalid datapoint list #{inspect datapoints}. Must be a list of atoms"

  defp validate_metadata(metadata) when is_list(metadata) or is_nil(metadata), do: :ok
  defp validate_metadata(metadata), do: raise ArgumentError, message: "Invalid metadata #{inspect metadata}. Must be a list"

  defp validate_value(value) when is_number(value), do: :ok
  defp validate_value(value), do: raise ArgumentError, message: "Invalid value #{inspect value}. Must be a number"
end
