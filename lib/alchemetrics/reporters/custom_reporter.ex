defmodule Alchemetrics.CustomReporter do
  @type t :: module
  @type opts :: Map.t

  @doc false
  @callback init(opts) :: {:ok, Map.t} | {:ok, Keyword.t} | {:error, String.t}

  @doc false
  @callback report(String.t, Atom.t, any, opts) :: any

  defmacro __using__(_) do
    quote do
      @behaviour Alchemetrics.CustomReporter

      @doc false
      def exometer_init(options) do
        options = options
        |> __MODULE__.init
        |> handle_options

        {:ok, options}
      end

      @doc false
      def exometer_report([scope, _] = metric_name, exometer_datapoint, _extra, value, options) do
        metadata = metadata_for(metric_name)
        datapoint = Alchemetrics.Exometer.Datapoints.from_scope(scope, exometer_datapoint)

        __MODULE__.report(metadata, datapoint, value, options)
        {:ok, options}
      end

      @doc """
      Enables the reporter. All datasets created **after** the reporter is enabled will subscribe to this reporter.

      ## Params
        - `options`: Start up options.
      """
      def enable(options \\ [])
      def enable(options) when is_list(options), do: Alchemetrics.ReporterStarter.start_reporter(__MODULE__, options)
      def enable(options), do: raise ArgumentError, "Invalid options #{inspect options}. Must be a Keyword list"


      @doc """
      Disables the reporter. All subscribed data sets will unsubscribe from this reporter.
      """
      def disable, do: :exometer_report.disable_reporter(__MODULE__)

      defp metadata_for(metric_name) do
        metric_name
        |> alchemetrics_data
        |> Map.get(:metadata)
        |> Enum.into([])
      end

      defp alchemetrics_data(metric_name) do
        metric_name
        |> :exometer.info
        |> Keyword.get(:options)
        |> Keyword.get(:__alchemetrics__, %{metadata: %{}})
      end

      defp handle_options({:ok, options}) when is_list(options) or is_map(options), do: options |> Enum.into([])
      defp handle_options({:ok, options}), do: raise ArgumentError, "Invalid CustomReporter options: #{inspect options}. Must be a Keyword or Map"

      defp handle_options({:error, message}) when is_bitstring(message), do: raise ErlangError, "The following error occurred while trying to start #{__MODULE__}: #{message}"
      defp handle_options({:error, _}), do: raise ErlangError, "An unexpected error occurred while starting #{__MODULE__}"

      defp handle_options(_), do: raise ArgumentError, "Invalid return value to #{__MODULE__}.init/1 function. It should be {:ok, opts} or {:error, opts}"

      @doc false
      def exometer_subscribe(_, _, _, _, opts), do: {:ok, opts}
      @doc false
      def exometer_unsubscribe(_, _, _, opts), do: {:ok, opts}
      @doc false
      def exometer_call(_, _, opts), do: {:ok, opts}
      @doc false
      def exometer_cast(_, opts), do: {:ok, opts}
      @doc false
      def exometer_info(_, opts), do: {:ok, opts}
      @doc false
      def exometer_newentry(_, opts), do: {:ok, opts}
      @doc false
      def exometer_setopts(_, _, _, opts), do: {:ok, opts}
      @doc false
      def exometer_terminate(_, _), do: nil
    end
  end
end
