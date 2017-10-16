defmodule AlchemetricsTest do
  use ExUnit.Case
  import Mock
  import Matchers
  alias Alchemetrics.Producer

  @histogram_event %Alchemetrics.Event{
    datapoints: Alchemetrics.Exometer.Datapoints.histogram,
    metadata: [measure: :test_elapsed_time],
    value: 100
  }

  @spiral_event %Alchemetrics.Event{
    datapoints: Alchemetrics.Exometer.Datapoints.spiral,
    metadata: [task: :tests_runned],
    value: 2
  }

  defmacro mock_basic_report(expression) do
    quote do
      with_mock Alchemetrics, [:passthrough], [report: fn
          _, value when not(is_function(value)) -> nil
          value, metadata -> :meck.passthrough([value, metadata])
      end] do
        unquote(expression)
      end
    end
  end

  describe "#report(value, metadata)" do
    test_with_mock "enqueue an event with the given value and metadata and with histogram datapoints", Alchemetrics.Producer, [:passthrough], [] do
      Alchemetrics.report(100, measure: :test_elapsed_time)
      assert called Producer.enqueue(@histogram_event)
    end

    test_with_mock "accepts complex values on keyword list", Alchemetrics.Producer, [:passthrough], [] do
      complex_metadata = [data: %{measure: :test_elapsed_time, file: "test/alchemetrics.exs"}]
      event = %Alchemetrics.Event{@histogram_event | metadata: complex_metadata}
      Alchemetrics.report(100, complex_metadata)
      assert called Producer.enqueue(event)
    end

    test "raises ArgumentError if an invalid value is provided" do
      assert_raise(ArgumentError, fn -> Alchemetrics.report("1", environment: :test) end)
      assert_raise(ArgumentError, fn -> Alchemetrics.report(:one, environment: :test) end)
      assert_raise(ArgumentError, fn -> Alchemetrics.report([value: 1], environment: :test) end)
      assert_raise(ArgumentError, fn -> Alchemetrics.report(%{value: 1}, environment: :test) end)
    end

    test "raises ArgumentError if metadata is not a keyword list" do
      assert_raise(ArgumentError, fn -> Alchemetrics.report(1, %{environment: :test}) end)
      assert_raise(ArgumentError, fn -> Alchemetrics.report(1, "environment_test") end)
      assert_raise(ArgumentError, fn -> Alchemetrics.report(1, %{environment: :test}) end)
    end

    test_with_mock "accepts a single atom as a name and report as name metadata", Alchemetrics.Producer, [:passthrough], [] do
      Alchemetrics.report(100, :something)
      event = %Alchemetrics.Event{@histogram_event | metadata: [name: :something]}
      assert called Producer.enqueue(event)
    end
  end

  describe "#report(metadata, function)" do
    @execution_time 100_000 # microseconds

    test "call report with the time (in microseconds) spent on the block execution" do
      mock_basic_report do
        Alchemetrics.report([measure: :test_elapsed_time], fn ->
          # execute code to measure execution time
          Process.sleep(@execution_time |> div(1000))
        end)
        assert called Alchemetrics.report(close_to(@execution_time), measure: :test_elapsed_time)
      end
    end

    test "repass block's return" do
      mock_basic_report do
        returned = Alchemetrics.report([measure: :test_elapsed_time], fn ->
          :code_return
        end)
        assert returned == :code_return
      end
    end
  end

  describe "#increment_by" do
    test_with_mock "enqueue an event with the given value and metadata and with histogram datapoints", Alchemetrics.Producer, [:passthrough], [] do
      Alchemetrics.increment_by(2, task: :tests_runned)
      assert called Producer.enqueue(@spiral_event)
    end

    test_with_mock "accepts complex values on keyword list", Alchemetrics.Producer, [:passthrough], [] do
      complex_metadata = [data: %{task: :tests_runned, file: "test/alchemetrics.exs"}]
      event = %Alchemetrics.Event{@spiral_event | metadata: complex_metadata}
      Alchemetrics.increment_by(2, complex_metadata)
      assert called Producer.enqueue(event)
    end

    test "raises ArgumentError if an invalid value is provided" do
      assert_raise(ArgumentError, fn -> Alchemetrics.increment_by("1", environment: :test) end)
      assert_raise(ArgumentError, fn -> Alchemetrics.increment_by(:one, environment: :test) end)
      assert_raise(ArgumentError, fn -> Alchemetrics.increment_by([value: 1], environment: :test) end)
      assert_raise(ArgumentError, fn -> Alchemetrics.increment_by(%{value: 1}, environment: :test) end)
    end

    test "raises ArgumentError if metadata is not a keyword list" do
      assert_raise(ArgumentError, fn -> Alchemetrics.increment_by(2, %{environment: :test}) end)
      assert_raise(ArgumentError, fn -> Alchemetrics.increment_by(2, "environment_test") end)
      assert_raise(ArgumentError, fn -> Alchemetrics.increment_by(2, %{environment: :test}) end)
    end

    test_with_mock "accepts a single atom as a name and report as name metadata", Alchemetrics.Producer, [:passthrough], [] do
      Alchemetrics.increment_by(2, :something)
      event = %Alchemetrics.Event{@spiral_event | metadata: [name: :something]}
      assert called Producer.enqueue(event)
    end
  end

  describe "#increment" do
    test_with_mock "enqueue an event with value 1, the given metadata and spiral  datapoints", Alchemetrics.Producer, [:passthrough], [] do
      Alchemetrics.increment(task: :tests_runned)
      event = %Alchemetrics.Event{@spiral_event | value: 1}
      assert called Producer.enqueue(event)
    end

    test_with_mock "accepts complex values on keyword list", Alchemetrics.Producer, [:passthrough], [] do
      complex_metadata = [data: %{task: :tests_runned, file: "test/alchemetrics.exs"}]
      event = %Alchemetrics.Event{@spiral_event | metadata: complex_metadata, value: 1}
      Alchemetrics.increment(complex_metadata)
      assert called Producer.enqueue(event)
    end

    test "raises ArgumentError if metadata is not a keyword list" do
      assert_raise(ArgumentError, fn -> Alchemetrics.increment(%{environment: :test}) end)
      assert_raise(ArgumentError, fn -> Alchemetrics.increment("environment_test") end)
      assert_raise(ArgumentError, fn -> Alchemetrics.increment(%{environment: :test}) end)
    end

    test_with_mock "accepts a single atom as a name and report as name metadata", Alchemetrics.Producer, [:passthrough], [] do
      Alchemetrics.increment(:something)
      event = %Alchemetrics.Event{@spiral_event | metadata: [name: :something], value: 1}
      assert called Producer.enqueue(event)
    end
  end
end
