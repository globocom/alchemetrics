defmodule Alchemetrics do
  alias Alchemetrics.Event
  alias Alchemetrics.Producer

  @moduledoc """
  Data Collection Interface

  All collected values follow the same flow:
    1. They are stored in a data set and stay there for a configurable time span;
    2. After that time span all measurements are applied to these values.
    3. Those measurements are sent to the Backends;
    4. The data set is reset

  This document provides a detailed explanation about each one of those steps.

  ## Collection of Values
  All collected values are stored in data sets. When collecting a value, you must identify it using the collection metadata. Collected values that have similar metadata are stored in the same dataset. If a collected value can not be stored in any existing data set, a new one is created.
  Each value accumulated in the data set will stay there for a configurable time interval. At the end of this interval, the data set will be measured.

  ## Data Set Measurement
  Measuring a data set is to perform a certain calculation on the data accumulated in it. The types of measurement include, but are not limited to, the mean, percentiles and sum of these values.
  The measurements that will be applied to a dataset depend on how the data was collected. Currently, Alchemetrics supports two types of collection: increments and reports.

  Each of the measurements generates a different data, which is sent to the `Backends` configured in the application. After that the data set is reset.
  Currently, Alchemetrics supports two types of data set: Increment Data Sets and Generic Data Sets.  The measurements that will be applied to a data set depend on its type.

  ### Increment Data Sets
  The values collected through the `increment_by/2` and `increment/1` functions will be stored in `Increment Data Sets`.
  The following measurements are available for this type of data set:

    - `:last_interval`: Represents the sum of all values collected in the last time interval.
    - `:total`: Represents the total sum since the first report.

  ### Increment Examples:
  ```elixir
  # Collecting 5 requests within the same time range:
  Alchemetrics.increment(requests_on: %{controller: UsersController, action: :info})
  Alchemetrics.increment(requests_on: %{controller: UsersController, action: :info})
  Alchemetrics.increment(requests_on: %{controller: UsersController, action: :info})
  Alchemetrics.increment(requests_on: %{controller: UsersController, action: :info})
  Alchemetrics.increment(requests_on: %{controller: UsersController, action: :info})

  # The data set is measured and the value is sent to the ConsoleBackend.
  # After that, the data set is reset.
  # The ConsoleBackend will print each one of the measurements
  # Printing :last_interval
  %{datapoint: :last_interval, requests_on: %{action: :info, controller: UsersController}, value: 5}
  # Printing :total
  %{datapoint: :total, requests_on: %{action: :info, controller: UsersController}, value: 5}

  # No increments were made on the last interval.
  # So, when the measurement is made, the last interval sum will be zero, but the total is kept at 5:
  %{datapoint: :last_interval, requests_on: %{action: :info, controller: UsersController}, value: 0}
  %{datapoint: :total, requests_on: %{action: :info, controller: UsersController}, value: 5}
  ```

  ### Generic Data Sets
  The values collected through the `report/2` function are stored in a `Generic Data Set`. The measurements made on these data sets are more general. While the values stored by the increments are only added together, in this type of data set many other measurement types are also available.

    - `:p99`: The 99th percentile of the data set.
    - `:p95`: The 95th percentile of the data set.
    - `:avg`: The average of the data set.
    - `:min`: The minimum value at the data set.
    - `:max`: The maximum value at the data set.
    - `:last_interval`: Like in the Increment Data Set, the sum on the last interval is also available here.
    - `:total`: Like in the Increment Data Set, the total sum since the first report is also available here.

  ### Report Examples:

  ```elixir
  Alchemetrics.report(1, response_time_on: %{controller: UsersController, action: :info})
  Alchemetrics.report(99, response_time_on: %{controller: UsersController, action: :info})
  %{datapoint: :max, response_time_on: %{action: :info, controller: UsersController}, value: 99}
  %{datapoint: :min, response_time_on: %{action: :info, controller: UsersController}, value: 1}
  %{datapoint: :avg, response_time_on: %{action: :info, controller: UsersController}, value: 50}
  %{datapoint: :p95, response_time_on: %{action: :info, controller: UsersController}, value: 99}
  %{datapoint: :p99, response_time_on: %{action: :info, controller: UsersController}, value: 99}
  %{datapoint: :last_interval, response_time_on: %{action: :info, controller: UsersController}, value: 100}
  %{datapoint: :total, response_time_on: %{action: :info, controller: UsersController}, value: 100}
  ```
  """


  @doc """
  Collect a value into a Generic Data Set.

  ## Params:
    - `value`: The collected value. Can be any integer
    - `name`: Identifies the data set where this value should be stored. Can be an `atom` or a `KeywordList`.
  """
  def report(value, name) when is_atom(name), do: report(value, [name: name])
  def report(value, metadata) do
    create_event(value, metadata, Alchemetrics.Exometer.Datapoints.histogram)
    |> Producer.enqueue
  end

  @doc """
  Similar to `increment/1`, but accept any value other than 1.

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
  Increment the count into an Increment Data Set by 1.

  ## Params:
    - `name`: Identifies the data set where this value should be stored. Can be an `atom` or a `KeywordList`.

  ## Example:
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
