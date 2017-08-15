defmodule Alchemetrics.ReporterStarterTest do
  use ExUnit.Case

  setup do
    :exometer_report.remove_reporter(FakeReporter)
    :ok
  end

  describe "#init" do
    test "starts all reporters on the :reporter_list apllication variable" do
      Alchemetrics.ReporterStarter.init(:ok)
      assert [{FakeReporter, _}] = :exometer_report.list_reporters
    end
  end

  describe "#start_reporter" do
    test "adds a new reporter from given module and options" do
      Alchemetrics.ReporterStarter.start_reporter(FakeReporter, [])
      :timer.sleep 10
      assert [{FakeReporter, _}] = :exometer_report.list_reporters
    end
  end
end

# We need this because :exometer_reporter.add_reporter crashes if
# it is called with an invalid module that does not implements
# exometer_report behaviour
defmodule FakeReporter do
  use Alchemetrics.CustomReporter
  def init(_), do: []
  def report(_), do: []
end
