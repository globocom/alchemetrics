defmodule Alchemetrics.MetricDataTest do
  use ExUnit.Case
  alias Alchemetrics.MetricData
  
  describe "Metric data" do
    test "contains client details" do
      metric = MetricData.build([], nil, nil, %{})
      assert metric[:ip] == expected_ip()
      refute metric[:timestamp] == nil
    end

    @fake_value 20
    @fake_datapoint :min
    test "contains metric basic data" do
      metric = MetricData.build([name: "some_metric"], @fake_datapoint, @fake_value, %{})
      assert metric[:name] == "some_metric"
      assert metric[:value] == @fake_value
      assert metric[:data_point] == @fake_datapoint
    end

    test "converts data_point to string if it is number" do
      metric = MetricData.build([name: "some_metric"], 99, nil, %{})
      assert metric[:data_point] == "99"
    end

    test "merges with metadata" do
      metric = MetricData.build([name: "some_metric"], :max, 10, %{group: "database", type: "ecto"})
      assert metric[:ip] == expected_ip()
      refute metric[:timestamp] == nil
      assert metric[:name] == "some_metric"
      assert metric[:value] == 10
      assert metric[:data_point] == :max
      
      refute metric[:metadata] != nil
      assert metric[:group] == "database"
      assert metric[:type] == "ecto"
    end
  end
  
  defp expected_ip do
    {:ok, [{node, _, _} | _]} = :inet.getif
    node 
    |> Tuple.to_list
    |> Enum.join(".")
  end
end
