<h1 align="center">Alchemetrics</h1>

<p align="center">
  <img alt="Alchemetrics" src="https://github.com/globocom/alchemetrics/blob/master/assets/alchemetrics.png?raw=true" width="128">
</p>

<p align="center">
  Metrics collection and reporting for Elixir applications.
</p>

<p align="center">
  <a href="https://travis-ci.org/globocom/alchemetrics">
    <img alt="Travis" src="https://travis-ci.org/globocom/alchemetrics.svg">
  </a>
  <a href='https://coveralls.io/github/globocom/alchemetrics?branch=master'>
    <img src='https://coveralls.io/repos/github/globocom/alchemetrics/badge.svg?branch=master' alt='Coverage Status' />
  </a>
  <a href="https://hex.pm/packages/alchemetrics">
    <img alt="Hex" src="https://img.shields.io/hexpm/dt/alchemetrics.svg">
  </a>
</p>

## About
Alchemetrics makes life easier for anyone who wants to report and distribute metrics from an Elixir application. The metrics can help you to measure performance, detect errors or track information about your application.

Alchemetrics makes use of [GenStage](https://hexdocs.pm/gen_stage/GenStage.html) to ensure that collecting and submitting metrics will not impact application performance.

Each metric report creates a new event that follows the GenStage flow. With the help of the [ConsumerSupervisor](https://hexdocs.pm/gen_stage/ConsumerSupervisor.html), your metrics are distributed with little impact to the application performance.

Documentation is available at [HexDocs](https://hexdocs.pm/alchemetrics/api-reference.html)

## Installation

Alchemetrics is available on [Hex](https://hex.pm/packages/alchemetrics). All you have to do is to add it to `mix.exs` as a test dependency.

```elixir
def deps do
  [{:alchemetrics, "~> 0.5.2"}]
end
```

## Reports
Reports are made via calls to Alchemetrics functions. It is through reports that Alchemetrics stores a value to be measured and sent to the backends. Further details about reports can be found in the [documentation available in HexDocs](https://hexdocs.pm/alchemetrics/0.5.2/Alchemetrics.html).


## Backends
Collected metrics are typically stored in some type of datastore, such as Logstash and Influxdb. Alchemetrics uses the concept of backends to distribute the metrics to these data stores. More details can be found in the [documentation about custom backends](https://hexdocs.pm/alchemetrics/0.5.2/Alchemetrics.CustomBackend.html).

When a dataset is created, it subscribes to all backends enabled on the application. Datasets created before a backend is enabled will not subscribe to the new backend. Also, when a backend is disabled, all datasets will unsubscribe from it.

### ConsoleBackend
Alchemetrics comes with a built-in backend called `Alchemetrics.ConsoleBackend`. This backend sends yor metrics to the console and is very useful when debugging.

You can enable `Alchemetrics.ConsoleBackend` when your application boot by adding it to yor backend list:

```elixir
# config/config.exs

config :alchemetrics,
  backends: [
    {Alchemetrics.ConsoleBackend, []}
  ]
```

You can also enable it on the console:

```elixir
# iex -S mix

iex(1)> Alchemetrics.ConsoleBackend.enable
Starting Elixir.Alchemetrics.ConsoleBackend with following options: []
:ok
iex(2)> Alchemetrics.report(100, :test)
:ok
iex(3)> %{datapoint: :avg, name: :test, options: [], value: 100}
%{datapoint: :max, name: :test, options: [], value: 100}
%{datapoint: :min, name: :test, options: [], value: 100}
%{datapoint: :p95, name: :test, options: [], value: 100}
%{datapoint: :p99, name: :test, options: [], value: 100}
%{datapoint: :last_interval, name: :test, options: [], value: 100}
%{datapoint: :total, name: :test, options: [], value: 100}
```

## Erlang VM metrics
Alchemetrics automatically collects some information about Erlang's VM, like memory and run queue. This is disabled by default, but you can enable it on the configs:

```elixir
# config/config.exs
config :alchemetrics, instrument_beam: true
```

This will enable the report of some data from Erlang's VM:

```elixir
%{datapoint: :memory_atom, options: [], type: :memory, value: 621465}
%{datapoint: :memory_binary, options: [], type: :memory, value: 392504}
%{datapoint: :memory_ets, options: [], type: :memory, value: 1365728}
%{datapoint: :memory_processes, options: [], type: :memory, value: 10513080}
%{datapoint: :memory_total, options: [], type: :memory, value: 38397232}
%{datapoint: :system_runqueue, options: [], type: :system, value: 1}
```

### Getting Started: Instrumenting requests on a Phoenix application
Let's show an example of how Alchemetrics could be used to instrument a Phoenix application with the help of Plug:

In this example application we will measure:

  - The **number of requests** for each route of the application grouped by the status of the response;
  - The **response times** (`average`, `percentiles`, `max` and `min`) of each route;

The collected metrics will be printed to the console by `Alchemetrics.ConsoleBackend`. To do this, we need to enable it in the settings:

```elixir
# config/config.exs

config :alchemetrics,
  backends: [
    [module: Alchemetrics.ConsoleBackend, []]
  ]
```

> Let's create the RequestInstrumentor plug:

```elixir
# lib/my_app_web/plugs/request_count.ex

defmodule RequestInstrumentor do
  @behaviour Plug

  def init(opts \\ []), do: opts
  def call(conn, opts), do: count_request(conn)

  defp count_request(conn) do
    start = System.monotonic_time()
    Plug.Conn.register_before_send(conn, fn conn ->
      stop = System.monotonic_time()
      diff = System.convert_time_unit(stop - start, :native, :micro_seconds)
      # report throughput
      Alchemetrics.increment(request_count: %{method: conn.method, path: conn.request_path, status: conn.status})
      # report request time
      Alchemetrics.report(diff, request_time: %{method: conn.method, path: conn.request_path})
      conn
    end)
  end
end
```

> Plug it on Phoenix Endpoint:

```elixir
defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  plug RequestInstrumentor
  ...
end
```

> Request your application:

```bash
$ mix phx.server
$ curl localhost:4000/
```

> Information about the request will show on application console:

```elixir
%{datapoint: :last_interval, options: [], requests_for: %{method: "GET", path: "/", status: 200}, value: 1}
%{datapoint: :total, options: [], requests_for: %{method: "GET", path: "/", status: 200}, value: 1}
%{datapoint: :avg, options: [], request_time: %{method: "GET", path: "/", status: 200}, value: 44069}
%{datapoint: :max, options: [], request_time: %{method: "GET", path: "/", status: 200}, value: 44069}
%{datapoint: :min, options: [], request_time: %{method: "GET", path: "/", status: 200}, value: 44069}
%{datapoint: :p95, options: [], request_time: %{method: "GET", path: "/", status: 200}, value: 44069}
%{datapoint: :p99, options: [], request_time: %{method: "GET", path: "/", status: 200}, value: 44069}
%{datapoint: :last_interval, options: [], request_time: %{method: "GET", path: "/", status: 200}, value: 44069}
%{datapoint: :total, options: [], request_time: %{method: "GET", path: "/", status: 200}, value: 44069}
```

> If you request an inexistent route, the reports will show 404 status code:

```elixir
%{datapoint: :last_interval, options: [], requests_for: %{method: "GET", path: "/invalid_route", status: 404}, value: 1}
%{datapoint: :total, options: [], requests_for: %{method: "GET", path: "/invalid_route", status: 404}, value: 1}
%{datapoint: :avg, options: [], request_time: %{method: "GET", path: "/invalid_route", status: 404}, value: 39558}
%{datapoint: :max, options: [], request_time: %{method: "GET", path: "/invalid_route", status: 404}, value: 39558}
%{datapoint: :min, options: [], request_time: %{method: "GET", path: "/invalid_route", status: 404}, value: 39558}
%{datapoint: :p95, options: [], request_time: %{method: "GET", path: "/invalid_route", status: 404}, value: 39558}
%{datapoint: :p99, options: [], request_time: %{method: "GET", path: "/invalid_route", status: 404}, value: 39558}
%{datapoint: :last_interval, options: [], request_time: %{method: "GET", path: "/invalid_route", status: 404}, value: 39558}
%{datapoint: :total, options: [], request_time: %{method: "GET", path: "/invalid_route", status: 404}, value: 39558}
```

For more details about reports, metrics, datasets, backends and all Alchemetrics concepts, take a look at the [docs](https://hexdocs.pm/alchemetrics/0.5.2/api-reference.html).
