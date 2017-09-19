defmodule Alchemetrics.Exometer.DatapointsTest do
  use ExUnit.Case

  alias Alchemetrics.Exometer.Datapoints

  test "spiral returns the list of spiral datapoints" do
    assert Datapoints.spiral == [:last_interval, :total]
  end

  describe "#histogram" do
    test "returns the list of histogram datapoints" do
      assert Datapoints.histogram == [:p99, :p95, :avg, :min, :max, :last_interval, :total]
    end
  end

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

  describe "#to_exometer" do
    test "transform a list of Alchemetrics datapoints into Exometer" do
      assert Datapoints.to_exometer(:histogram, [:p99, :p95, :avg, :min, :max]) == [:mean, :max, :min, 95, 99]
      assert Datapoints.to_exometer(:spiral, [:last_interval, :total]) == [:one, :count]
    end

    test "returns empty array if provided datapoints does not match with the given scope" do
      assert Datapoints.to_exometer(:spiral, [:p99, :p95, :avg, :min, :max]) == []
    end

    test "returns empty array if an invalid scope is provided" do
      assert Datapoints.to_exometer(:invalid, [:p99, :p95, :avg, :min, :max]) == []
    end

    test "returns empty array if a invalid datapoint list is provided" do
      assert Datapoints.to_exometer(:spiral, [:invalid1, :invalid2]) == []
    end

    test "returns a list with the valid datapoints" do
      assert Datapoints.to_exometer(:spiral, [:last_interval, :invalid]) == [:one]
    end

    test "returns empty array if an empty datapoint list is provided" do
      assert Datapoints.to_exometer(:spiral, []) == []
    end
  end

  test "#validate raises ArgumentError if at least one of the datapoint on the given list is invalid" do
      assert_raise ArgumentError, fn -> Datapoints.validate([:invalid, :p99]) end
      assert_raise ArgumentError, fn -> Datapoints.validate([:p99, :invalid]) end
      assert_raise ArgumentError, fn -> Datapoints.validate([:invalid]) end
  end

  describe "#scopes_for" do
    test "returns the scopes for the given datapoints" do
      assert Datapoints.scopes_for([:p99, :p95]) == [:histogram]
      assert Datapoints.scopes_for([:last_interval, :total]) == [:spiral]
      assert Datapoints.scopes_for([:p99, :last_interval, :p95]) == [:histogram, :spiral]
    end

    test "raises ArgumentError if one of the datapoints are invalid" do
      assert_raise ArgumentError, fn -> Datapoints.scopes_for([:invalid, :p99]) end
      assert_raise ArgumentError, fn -> Datapoints.scopes_for([:p99, :invalid]) end
      assert_raise ArgumentError, fn -> Datapoints.scopes_for([:invalid]) end
    end
  end
end
