<h1 align="center">Alchemetrics</h1>

<p align="center">
  <img alt="Playkit" src="https://github.com/globocom/alchemetrics/blob/master/assets/alchemetrics.png?raw=true" width="128">
</p>

<p align="center">
  Elixir metrics reporter and collector
</p>

<p align="center">
  <a href="https://travis-ci.org/globocom/alchemetrics">
    <img alt="Travis" src="https://travis-ci.org/globocom/alchemetrics.svg">
  </a>
  <a href="https://hex.pm/packages/alchemetrics">
    <img alt="Hex" src="https://img.shields.io/hexpm/dt/alchemetrics.svg">
  </a>
</p>

## About
Alchemetrics makes life easier for anyone who wants to collect and report metrics from an Elixir application.

Under the table, Alchemetrics uses Exometer, but you can create custom reporters, set them up, and report metrics without having to write a single line in Erlang.

## Performance
Alchemetrics makes use of [GenStage](https://hexdocs.pm/gen_stage/GenStage.html) to ensure that collecting and submitting metrics will not impact application performance.

Each metric report creates a new event that follows the GenStage flow. With the help of the [ConsumerSupervisor](https://hexdocs.pm/gen_stage/ConsumerSupervisor.html), which creates a new process for each of them, they are handled by the reporters.

The maximum number of processes is a configurable parameter. With more processes, the accuracy of values is higher, but the performance impact will also be greater.

## Debugging
Alchemetrics comes with a reporter called Alchemetrics.LoggerReporter, which just write all the stuff it receives into debug logs. It can be useful to visualize how reporters are receiving metrics from your application.

Please note that Alchemetrics allows multiple reporters to be used at the same time and each of them will receive the metrics in the same way.

### Example:
```
iex(1)> Alchemetrics.ReporterStarter.start_reporter(Alchemetrics.LoggerReporter, [application: "MyApp"])
:ok
iex(2)>
23:20:40.695 [debug] Starting Elixir.Alchemetrics.LoggerReporter with following options: [application: "MyApp"]
iex(2)> Alchemetrics.report("some_metric", 1)
:ok
iex(3)>
23:21:12.691 [debug] Reporting: %{metric: :last_interval, name: "some_metric", options: [metadata: [], application: "MyApp"], value: 1}
```

## Creating your own custom reporters
A custom reporter is a module that implements a behavior.

It should make use of the `Alchemetrics.CustomReporter.__using__` macro and implement two functions: `init/1` and `report/4`.

```elixir
## my_app/metrics/my_reporter.ex

defmodule MyApp.Metrics.MyReporter do
  use Alchemetrics.CustomReporter

  def init(opts) do
    IO.puts "I'm called once the reporter is started! My options: #{inspect opts}"
  end

  def report(name, metric, value, opts) do
    IO.puts "I am called every time a metric is sent from this reporter! #{name} | #{metric} | #{value} | #{inspect opts}"
  end
end
```
And let's check our reporter at `iex`:

```
iex(1)> Alchemetrics.ReporterStarter.start_reporter(MyApp.Metrics.MyReporter,  [owner: "my_team"])
:ok
I'm called once the reporter is started! My options: [owner: "my_team"]
iex(2)> Alchemetrics.report("my_metric", 1000)
:ok
iex(3)> I am called every time a metric is sent from this reporter! my_metric | last_interval | 1000 | [metadata: [], owner: "my_team"]
```
