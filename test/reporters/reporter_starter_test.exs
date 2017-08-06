defmodule Alchemetrics.ReporterStarterTest do
  use ExUnit.Case
  import Mock

  @reporter_list [
    [module: SomeReporter, opts: []],
    [module: AnotherReporter, opts: [some: "options"]]
  ]

  describe "#init" do
    test "starts all reporters on the :reporter_list apllication variable" do
      with_mocks([
        {:exometer_report, [], [add_reporter: fn(_, _) -> :ok end]},
        {Application, [], [get_env: fn(_, _, _) -> @reporter_list end]},
      ]) do
        Alchemetrics.ReporterStarter.init(:ok)
        assert called :exometer_report.add_reporter(SomeReporter, [])
        assert called :exometer_report.add_reporter(AnotherReporter, [some: "options"])
      end
    end
  end

  describe "#start_reporter" do
    test "adds a new reporter from given module and options" do
      with_mock(:exometer_report, [add_reporter: fn(_, _) -> :ok end]) do
        Alchemetrics.ReporterStarter.start_reporter([module: SomeOtherReporter, opts: []])
        assert called :exometer_report.add_reporter(SomeOtherReporter, [])
      end
    end
  end
end
