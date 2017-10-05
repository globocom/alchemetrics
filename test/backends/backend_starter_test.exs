defmodule Alchemetrics.BackendStarterTest do
  use ExUnit.Case

  setup do
    :exometer_report.remove_reporter(FakeBackend)
    :ok
  end

  describe "#init" do
    test "starts all reporters on the :backends apllication variable" do
      Alchemetrics.BackendStarter.init(:ok)
      assert [{FakeBackend, _}] = :exometer_report.list_reporters
    end
  end

  describe "#start_reporter" do
    test "adds a new reporter from given module and options" do
      Alchemetrics.BackendStarter.start_reporter(FakeBackend, [])
      :timer.sleep 10
      assert [{FakeBackend, _}] = :exometer_report.list_reporters
    end
  end
end
