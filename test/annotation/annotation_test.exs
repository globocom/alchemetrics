defmodule Alchemetrics.AnnotationTest do
  use ExUnit.Case
  import Mock

  describe "When a function is annotated" do
    test_with_mock "report function calls with 'Elixir.Module.function/arity' format", Alchemetrics, [:passthrough], [] do
      FakeAnnotatedModule.annotated_function
      assert called Alchemetrics.increment(function_calls: "Elixir.FakeAnnotatedModule.annotated_function/0")
    end

    test_with_mock "report time spend on function with 'Elixir.Module.function/arity' format", Alchemetrics, [:passthrough], [] do
      FakeAnnotatedModule.annotated_function
      assert called Alchemetrics.report(:_, function_time_spent: "Elixir.FakeAnnotatedModule.annotated_function/0")
    end

    test_with_mock "annotate all functions with same name and arity", Alchemetrics, [:passthrough], [] do
      FakeAnnotatedModule.multiple_clauses(1)
      assert called Alchemetrics.increment(function_calls: "Elixir.FakeAnnotatedModule.multiple_clauses/1")
      assert called Alchemetrics.report(:_, function_time_spent: "Elixir.FakeAnnotatedModule.multiple_clauses/1")
    end

    test_with_mock "works with recursive functions", Alchemetrics, [:passthrough], [] do
      FakeAnnotatedModule.recursive_function([1, 2, 3])
      assert called Alchemetrics.increment(function_calls: "Elixir.FakeAnnotatedModule.recursive_function/1")
      assert called Alchemetrics.report(:_, function_time_spent: "Elixir.FakeAnnotatedModule.recursive_function/1")
    end

    test_with_mock "works with function heads and default argument", Alchemetrics, [:passthrough], [] do
      FakeAnnotatedModule.head
      assert called Alchemetrics.increment(function_calls: "Elixir.FakeAnnotatedModule.head/1")
      assert called Alchemetrics.report(:_, function_time_spent: "Elixir.FakeAnnotatedModule.head/1")
    end

    test_with_mock "works with function heads and providing argument", Alchemetrics, [:passthrough], [] do
      FakeAnnotatedModule.head(2)
      assert called Alchemetrics.increment(function_calls: "Elixir.FakeAnnotatedModule.head/1")
      assert called Alchemetrics.report(:_, function_time_spent: "Elixir.FakeAnnotatedModule.head/1")
    end
  end
end
