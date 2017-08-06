defmodule Alchemetrics.ReporterStarterTest do
  use ExUnit.Case
  import Mock

  @reporter_list [
    [module: FakeReporter, opts: [some: "options"]]
  ]

  setup do
    :exometer_report.remove_reporter(FakeReporter)
    :ok
  end

  describe "#init" do
    test "starts all reporters on the :reporter_list apllication variable" do
      with_mock(Application, [get_env: fn(_, _, _) -> @reporter_list end]) do
        Alchemetrics.ReporterStarter.init(:ok)
        assert [{FakeReporter, _}] = :exometer_report.list_reporters
      end
    end
  end

  describe "#start_reporter" do
    test "adds a new reporter from given module and options" do
      Alchemetrics.ReporterStarter.start_reporter([module: FakeReporter, opts: []])
      :timer.sleep 1
      assert [{FakeReporter, _}] = :exometer_report.list_reporters
    end
  end
end

# We need this because :exometer_reporter.add_reporter crashes if
# it is called with an invalid module that does not implements
# exometer_report behaviour
defmodule FakeReporter do
  use Alchemetrics.CustomReporter
  def init(_), do: nil
  def report(_), do: nil
end
