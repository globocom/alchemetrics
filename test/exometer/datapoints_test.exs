defmodule Alchemetrics.Exometer.DatapointsTest do
  use ExUnit.Case

  alias Alchemetrics.Exometer.Datapoints

  describe "#metric_from_scope" do
    test "returns nil if scope is not valid" do
      assert is_nil(Datapoints.from_scope(:invalid, 99))
      assert is_nil(Datapoints.from_scope(:invalid, 95))
      assert is_nil(Datapoints.from_scope(:invalid, :mean))
      assert is_nil(Datapoints.from_scope(:invalid, :count))
      assert is_nil(Datapoints.from_scope(:invalid, :one))
    end

    test "returns nil if datapoint is not valid" do
      assert is_nil(Datapoints.from_scope(:spiral, :invalid))
      assert is_nil(Datapoints.from_scope(:histogram, :invalid))
    end

    test "returns the equivalent metric given the exometer datapoint and scope" do
      assert Datapoints.from_scope(:histogram, 99) == :p99
      assert Datapoints.from_scope(:histogram, 95) == :p95
      assert Datapoints.from_scope(:histogram, :mean) == :avg
      assert Datapoints.from_scope(:spiral, :count) == :total
      assert Datapoints.from_scope(:spiral, :one) == :last_interval
    end
  end
end
