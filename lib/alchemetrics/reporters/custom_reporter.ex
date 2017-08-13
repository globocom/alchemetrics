defmodule Alchemetrics.CustomReporter do
  @type t :: module
  @type opts :: Map.t

  @doc """
  This is called when the reporter is started. You can put some initialization code here, like connection stuff.

  The `opts` argument stores reporter specific configuration. You can set this parameter with `opts` option on `reporter_list` config.

  ```
  # The value of `opts` key is the argument of the init/1 function!
  config :alchemetrics, reporter_list: [
    [module: MyApp.DummyReporter, opts: [some_data: "hello!"]]
  ]
  ```
  """
  @callback init(opts) :: Map.t | Keyword.t

  @doc """
  This is called every time a metric datapoint is reported.

  For a metric which is reported every 10 seconds, this function will be called every 10 seconds for each one of its datapoints.
  """
  @callback report(String.t, Atom.t, any, opts) :: any

  defmacro __using__(_) do
    quote do
      @behaviour Alchemetrics.CustomReporter

      def exometer_init(options) do
        options = options
        |> __MODULE__.init
        |> handle_options

        {:ok, options}
      end

      def exometer_report([public_name, scope] = metric_name, data_point, _extra, value, options) do
        options = Keyword.put(options, :metadata, metadata_for(metric_name))
        metric = Alchemetrics.Exometer.Metric.metric_from_scope(scope, data_point)

        __MODULE__.report(public_name, metric, value, options)
        {:ok, options}
      end

      def enable(options \\ [])
      def enable(options) when is_list(options), do: Alchemetrics.ReporterStarter.start_reporter(__MODULE__, options)
      def enable(options), do: raise ArgumentError, "Invalid options #{inspect options}. Must be a Keyword list"

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

      defp handle_options({:error, message}) when is_bitstring(message), do: raise ArgumentError, "The following error occurred while trying to start #{__MODULE__}: #{message}"
      defp handle_options({:error, _}), do: raise ArgumentError, "An unexpected error occurred while starting #{__MODULE__}"

      defp handle_options(_), do: raise ArgumentError, "Invalid return value to #{__MODULE__}.init/1 function. It should be {:ok, opts} or {:error, opts}"

      def exometer_subscribe(_, _, _, _, opts), do: {:ok, opts}
      def exometer_unsubscribe(_, _, _, opts), do: {:ok, opts}
      def exometer_call(_, _, opts), do: {:ok, opts}
      def exometer_cast(_, opts), do: {:ok, opts}
      def exometer_info(_, opts), do: {:ok, opts}
      def exometer_newentry(_, opts), do: {:ok, opts}
      def exometer_setopts(_, _, _, opts), do: {:ok, opts}
      def exometer_terminate(_, _), do: nil
    end
  end
end
