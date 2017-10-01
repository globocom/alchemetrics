defmodule Alchemetrics do
  alias Alchemetrics.Event
  alias Alchemetrics.Producer

  @moduledoc """
  Data Report Interface

  All reported values follow the same flow:
    1. They are stored in a `data set` and stay there for a configurable time span;
    2. after that time span the `data set` is measured. Various measurements are made on the `data set`;
    3. The measurement results are sent to the backends;
    4. The data set is reset.

  This document provides a detailed explanation about each one of those steps.

  ## Value Report
  All collected values are stored in data sets. The reported value is identified by a name or by some metadata, which determines the set of data at which this value will be stored. Therefore, values with metadata or similar names are stored in the same data set. If a collected value can not be stored in any existing data set, a new one is created.
  Each value accumulated in the data set will stay there for a configurable time interval. At the end of this interval, the data set will be measured.

  ## Data Set Measurement
  Measuring a data set is to perform a certain calculation on the data accumulated in it. The types of measurement include the average calculation, percentiles and the sum of these values. Each of the measurements generates a different value, which is sent to the `Backends` configured in the application. After that, the data set is reset.

  When reporting a value through the `report/2` function, the following measurements will be applied:

    - `:p99`: The 99th percentile of the data set.
    - `:p95`: The 95th percentile of the data set.
    - `:avg`: The average of the data set.
    - `:min`: The minimum value at the data set.
    - `:max`: The maximum value at the data set.
    - `:last_interval`: Like in the Increment Data Set, the sum on the last interval is also available here.
    - `:total`: Like in the Increment Data Set, the total sum since the first report is also available here.

  ### Report Examples:
  ```elixir
  # Making two reports for the same data set in the same time interval
  Alchemetrics.report(1, response_time_on: %{controller: UsersController, action: :info})
  Alchemetrics.report(99, response_time_on: %{controller: UsersController, action: :info})
  # Each measurement is made in the data set and the result is sent to the backends
  # In this example the backend only prints the results of the measurements in the console
  %{datapoint: :max, response_time_on: %{action: :info, controller: UsersController}, value: 99}
  %{datapoint: :min, response_time_on: %{action: :info, controller: UsersController}, value: 1}
  %{datapoint: :avg, response_time_on: %{action: :info, controller: UsersController}, value: 50}
  %{datapoint: :p95, response_time_on: %{action: :info, controller: UsersController}, value: 99}
  %{datapoint: :p99, response_time_on: %{action: :info, controller: UsersController}, value: 99}
  %{datapoint: :last_interval, response_time_on: %{action: :info, controller: UsersController}, value: 100}
  %{datapoint: :total, response_time_on: %{action: :info, controller: UsersController}, value: 100}
  ```

  When reporting a value through the `increment/1` or `increment_by/2` functions, the following measurements will be applied:

    - `:last_interval`: The sum of all data set values on the last time interval.
    - `:total`: The total sum of the data set since the application boot.

  ### Increment Examples:
  ```elixir
  # Collecting 3 requests within the same time range:
  Alchemetrics.increment(requests_on: %{controller: UsersController, action: :info})
  Alchemetrics.increment(requests_on: %{controller: UsersController, action: :info})
  Alchemetrics.increment(requests_on: %{controller: UsersController, action: :info})

  # The data set is measured and the value is sent to the backend.
  # In this example the backend only prints the results of the measurements in the console
  # After that, the data set is reset.
  # The ConsoleBackend will print each one of the measurements
  # Printing :last_interval
  %{datapoint: :last_interval, requests_on: %{action: :info, controller: UsersController}, value: 3}
  # Printing :total
  %{datapoint: :total, requests_on: %{action: :info, controller: UsersController}, value: 3}

  # No increments were made on the last interval.
  # So, when the measurement is made, the last interval sum will be zero, but the total is kept at 3:
  %{datapoint: :last_interval, requests_on: %{action: :info, controller: UsersController}, value: 0}
  %{datapoint: :total, requests_on: %{action: :info, controller: UsersController}, value: 3}
  ```
  """

  @doc """
  Reports a generic value.

  The following measures will be applied:

    - `:p99`: The 99th percentile of the data set.
    - `:p95`: The 95th percentile of the data set.
    - `:avg`: The average of the data set.
    - `:min`: The minimum value at the data set.
    - `:max`: The maximum value at the data set.
    - `:last_interval`: Like in the Increment Data Set, the sum on the last interval is also available here.
    - `:total`: Like in the Increment Data Set, the total sum since the first report is also available here.

  ## Params:
    - `value`: The collected value. Can be any integer
    - `name`: Identifies the data set where this value should be stored. Can be an `atom` or a `KeywordList`.

  ## Usage:

  Reports are useful, to report generic values, like a response time for a given route. Therefore, you could create a Plug that reports the response time of a certain route:

  ```elixir
  defmodule MyApp.Plugs.RequestMeasurer do
    @behaviour Plug

    def init(opts \\ []), do: opts

    def call(conn, opts) do
      start = System.monotonic_time()
      Plug.Conn.register_before_send(conn, fn conn ->
        diff = System.convert_time_unit(System.monotonic_time() - start, :native, :micro_seconds)
        Alchemetrics.report(diff, request_time: %{
          method: conn.method,
          path: conn.request_path,
          status: conn.status
        })
        conn
      end)
    end
  end

  # my_app_web/endpoint.ex
  defmodule MyApp.Endpoint do
    use Phoenix.Endpoint, otp_app: :my_app

    plug MyApp.Plugs.RequestMeasurer
    ...
  end
  ```
  """
  def report(value, name) when is_atom(name), do: report(value, [name: name])
  def report(value, metadata) do
    create_event(value, metadata, Alchemetrics.Exometer.Datapoints.histogram)
    |> Producer.enqueue
  end

  @doc """
  Similar to `increment/1`, but accept any value other than 1.

  The following measures will be applied:

    - `:last_interval`: The sum of all data set values on the last time interval.
    - `:total`: The total sum of the data set since the application boot.

  ## Params:
    - `value`: The value to be collected. Can be any integer.
    - `name`: Identifies the data set where this value should be stored. Can be an `atom` or a `KeywordList`.
  """
  def increment_by(value, name) when is_atom(name), do: increment_by(value, [name: name])
  def increment_by(value, metadata) do
    create_event(value, metadata, Alchemetrics.Exometer.Datapoints.spiral)
    |> Producer.enqueue
  end

  @doc """
  Reports the value 1.

  The following measures will be applied:

    - `:last_interval`: The sum of all data set values on the last time interval.
    - `:total`: The total sum of the data set since the application boot.

  ## Params:
    - `name`: Identifies the data set where this value should be stored. Can be an `atom` or a `KeywordList`.

  ## Usage:
  Increments are useful, for example, to count the number of requests on a particular route in a Phoenix application.

  ```elixir
  defmodule MyAppWeb.UsersController do
    use MyAppWeb, :controller

    plug :count_request

    def info(conn, _params), do: json(conn, %{name: "Some User", email: "some_user@mycompany.org"})

    def count_request(conn, _) do
      Alchemetrics.increment(requests_at: %{
        controller: Phoenix.Controller.controller_module(conn),
        action: Phoenix.Controller.action_name(conn)
      })
      conn
    end
  end
  ```
  """
  def increment(name) when is_atom(name), do: increment_by(1, [name: name])
  def increment(metadata), do: increment_by(1, metadata)

  defp create_event(value, metadata, datapoints) do
    %{}
    |> Map.put(:metadata, metadata)
    |> Map.put(:datapoints, datapoints)
    |> Map.put(:value, value)
    |> Event.create
  end
end
