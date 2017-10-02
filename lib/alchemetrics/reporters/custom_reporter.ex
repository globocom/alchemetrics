defmodule Alchemetrics.CustomReporter do
  @type t :: module
  @type metadata :: Keyword.t
  @type measure :: Atom.t
  @type value :: Integer.t
  @type state :: Map.t | Keyword.t
  @type init_opts :: Keyword.t | Map.t

  @callback init(init_opts) :: {:ok, state} | {:ok, Keyword.t} | {:error, String.t} | {:error, Atom.t}
  @callback report(metadata, measure, value, state) :: any

  @moduledoc """
  Interface to create CustomReporters.

  The backends are responsible for distributing the measurement results. When a dataset is created, it subscribes to all enabled backends and send measurement results to them.

  Alchemetrics comes with a built-in backend named `Alchemetrics.ConsoleReporter` that prints all reported data to console. It can be very useful when debuging your metrics.

  ## Creating a CustomBackend
  The `Alchemetrics.CustomReporter__using__/1` macro will already include the behavior of custom reporter in a module. The behavior has two callbacks: `c:init/1` and `c:report/4`.

  The `c:init/1` callback is called at the moment the backend is initialized. This is where, for example, connections to external services are established, or sockets to send data via TCP/UDP are open.

  The `c:init/1` callback should return `{:ok, state}` or `{:error, reason}`.  If `{:ok, state}` is returned, the `state` is passed as argument to the `c:report/4` callback. If `{:error, reason}` is returned, the reporter will not be initialized, and an error will be raised.

  The `c:report/4` callback is called every time a dataset is measured. This is where the data is sent to the external service. The params for `c:report/4` are:
    - `t:metadata/0`: The dataset identifier.
    - `t:measure/0`: The measurement made on the dataset
    - `t:value/0`: The value to be distributed
    - `t:state/0`: The state returned from the `c:init/1` function

  ## Dataset subscription
  For the measurements of a dataset to be sent to a backend, the dataset must subscribe to it. By default, datasets automatically subscribe to all active backends at the time of their creation.

  When a backend is disabled, all datasets cancel their subscriptions. If that backend is reactivated, only the new datasets will be subscribed.

  ### Example

  Let's see the implementation of a backend that sends metrics to Logstash via UDP:

  ```elixir
  defmodule MyApp.Reporters.UDP do
    use Alchemetrics.CustomReporter

    def init(init_opts) do
      case gen_udp.open(0) do
        {:ok, sock} ->
          state = [socket: sock] ++ init_opts
          {:ok, state}
        {:error, reason} ->
          {:error, reason}
      end
    end

    def report(metadata, measure, value, state) do
      metadata = Enum.into(metadata, %{})
      base_report = %{measure: measure, value: value}
      Map.merge(base_report, metadata)
      |> Poison.encode!
      |> send_metric(state)
    end

    defp send_metric(data, state) do
      {sock, host, port} = extract_options(state)
      :gen_udp.send(sock, host, port, data)
    end

    defp extract_options(opts) do
      hostname = String.to_charlist(opts[:hostname])
      {opts[:socket], hostname, opts[:port]}
    end
  end
  ```

  You can configure your brand new reporter to be enabled when application boots. The `opts` key will be passed as argument to the `c:init/1` function.

  ```elixir
  # config/config.exs
  config :alchemetrics, reporter_list: [
    [module: MyApp.Reporters.UDP, opts: [hostname: "logstash.mycorp.com", port: 8888]]
  ]
  ```
  """

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
