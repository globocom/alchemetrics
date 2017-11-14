defmodule Alchemetrics.AnnotationTest do
  use ExUnit.Case
  import Mock

  describe "When a function is annotated" do
    test_with_mock "report function calls with 'Elixir.Module.function/arity' format", Alchemetrics, [:passthrough], [] do
      return = FakeAnnotatedModule.annotated_function

      assert called Alchemetrics.increment(function_calls: "Elixir.FakeAnnotatedModule.annotated_function/0")
      assert :meck.num_calls(Alchemetrics, :increment, :_) == 1

      assert return == 100
    end

    test_with_mock "report time spend on function with 'Elixir.Module.function/arity' format", Alchemetrics, [:passthrough], [] do
      return = FakeAnnotatedModule.annotated_function

      assert called Alchemetrics.report(:_, function_time_spent: "Elixir.FakeAnnotatedModule.annotated_function/0")
      assert :meck.num_calls(Alchemetrics, :report, :_) == 1

      assert return == 100
    end

    test_with_mock "annotate all functions with same name and arity", Alchemetrics, [:passthrough], [] do
      return1 = FakeAnnotatedModule.multiple_clauses(1)
      return2 = FakeAnnotatedModule.multiple_clauses(4)

      assert called Alchemetrics.increment(function_calls: "Elixir.FakeAnnotatedModule.multiple_clauses/1")
      assert :meck.num_calls(Alchemetrics, :increment, :_) == 2

      assert called Alchemetrics.report(:_, function_time_spent: "Elixir.FakeAnnotatedModule.multiple_clauses/1")
      assert :meck.num_calls(Alchemetrics, :report, :_) == 2

      assert return1 == 4
      assert return2 == 8
    end

    test_with_mock "works with recursive functions", Alchemetrics, [:passthrough], [] do
      return = FakeAnnotatedModule.recursive_function([1, 2, 3])

      assert called Alchemetrics.increment(function_calls: "Elixir.FakeAnnotatedModule.recursive_function/1")
      assert :meck.num_calls(Alchemetrics, :increment, :_) == 4

      assert called Alchemetrics.report(:_, function_time_spent: "Elixir.FakeAnnotatedModule.recursive_function/1")
      assert :meck.num_calls(Alchemetrics, :report, :_) == 4

      assert return == :ok
    end

    test_with_mock "works with function heads and default argument", Alchemetrics, [:passthrough], [] do
      return1 = FakeAnnotatedModule.head
      return2 = FakeAnnotatedModule.head(1)
      return3 = FakeAnnotatedModule.head(3)

      assert called Alchemetrics.increment(function_calls: "Elixir.FakeAnnotatedModule.head/1")
      assert :meck.num_calls(Alchemetrics, :increment, :_) == 3

      assert called Alchemetrics.report(:_, function_time_spent: "Elixir.FakeAnnotatedModule.head/1")
      assert :meck.num_calls(Alchemetrics, :report, :_) == 3

      assert return1 == 1
      assert return2 == 1
      assert return3 == 6
    end

    test_with_mock "does not instrument functions with same name but different arities", Alchemetrics, [:passthrough], [] do
      return1 = FakeAnnotatedModule.different_arity(10)
      return2 = FakeAnnotatedModule.different_arity(5, 8)

      assert called Alchemetrics.increment(function_calls: "Elixir.FakeAnnotatedModule.different_arity/1")
      assert :meck.num_calls(Alchemetrics, :increment, :_) == 1

      assert called Alchemetrics.report(:_, function_time_spent: "Elixir.FakeAnnotatedModule.different_arity/1")
      assert :meck.num_calls(Alchemetrics, :report, :_) == 1


      refute called Alchemetrics.increment(function_calls: "Elixir.FakeAnnotatedModule.different_arity/2")

      assert return1 == 10
      assert return2 == 13
    end
  end
end
