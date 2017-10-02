defmodule Alchemetrics.ExometerTest do
  use ExUnit.Case, async: false
  import Mock

  alias Alchemetrics.Exometer

  @metric %Alchemetrics.Exometer.Metric{name: ["my_metric", :spiral], value: 1, scope: :spiral}

  setup do
    :exometer.delete(@metric.name)
    :ok
  end

  describe "#update" do
    test "creates a metric if a metric with the given name does not exist" do
      assert :exometer.info(@metric.name) == :undefined
      Exometer.update(@metric)
      refute :exometer.info(@metric.name) == :undefined
    end

    test "does not try to create the same metric twice" do
      Exometer.update(@metric)
      with_mock(:exometer, [:passthrough], []) do
        Exometer.update(@metric)
        refute called :exometer.new(:_, :_, :_)
      end
    end

    test "register the metric into a reporter" do
      with_mock(:exometer_report, [:passthrough], [list_reporters: fn() -> [{SomeBackend, nil}] end]) do
        Exometer.update(@metric)
        assert called :exometer_report.subscribe(SomeBackend, @metric.name, :_, :_)
      end
    end

    test "register the metric into multiple reporters" do
      with_mock(:exometer_report, [:passthrough], [list_reporters: fn() -> [{SomeBackend, nil}, {AnotherBackend, nil}] end]) do
        Exometer.update(@metric)
        assert called :exometer_report.subscribe(SomeBackend, @metric.name, :_, :_)
        assert called :exometer_report.subscribe(AnotherBackend, @metric.name, :_, :_)
      end
    end
  end
end
