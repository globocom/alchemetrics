defmodule Alchemetrics.Annotation do
  alias Alchemetrics.Annotation.InstrumentedFunctionList
  alias Alchemetrics.Annotation.Function

  @moduledoc """
  Annotations allow you to automatically report the amount of calls and time spent on a particular function.

  They work with multiple clauses, guard clauses, recursion, function heads, and so on. However, only public functions can be annotated. The return value of annotated functions does not change.

  ## Example
  To annotate a function simply mark it with the tag `@alchemetrics instrument_function: true`. All functions defined in the module with the same name and arity will also be marked for instrumentation.

  ```elixir
  defmodule AnnotatedModule do
    use Alchemetrics.Annotation

    @alchemetrics instrument_function: true
    def annotated_function, do: IO.puts "I will be instrumented :)"

    def not_annotated, do: IO.puts "I will not be instrumented :("

    @alchemetrics instrument_function: true
    def multiple_clauses(a) when a > 3, do: a*2
    def multiple_clauses(a), do: a*4

    @alchemetrics instrument_function: true
    def recursive_function([]), do: nil
    def recursive_function([_|t]), do: recursive_function(t)

    @alchemetrics instrument_function: true
    def head(a \\ 1)
    def head(a) when a > 2, do: a*2
    def head(a), do: a
  end
  ```

  ## Report Format
  The annotated functions will be reported in the following formats:
    - `function_time_spent: "Elixir.Module.function/arity"`
    - `function_calls: "Elixir.Module.function/arity"`

  ```elixir
  iex(1)> Alchemetrics.ConsoleBackend.enable
  iex(2)> AnnotatedModule.annotated_function
  I will be instrumented :)
  :ok
  iex(3)>
  %{datapoint: :last_interval, function_calls: "Elixir.AnnotatedModule.annotated_function/0", value: 1}
  %{datapoint: :total, function_calls: "Elixir.AnnotatedModule.annotated_function/0", value: 1}
  %{datapoint: :avg, function_time_spent: "Elixir.AnnotatedModule.annotated_function/0", value: 0}
  %{datapoint: :max, function_time_spent: "Elixir.AnnotatedModule.annotated_function/0", value: 0}
  %{datapoint: :min, function_time_spent: "Elixir.AnnotatedModule.annotated_function/0", value: 0}
  %{datapoint: :p95, function_time_spent: "Elixir.AnnotatedModule.annotated_function/0", value: 0}
  %{datapoint: :p99, function_time_spent: "Elixir.AnnotatedModule.annotated_function/0", value: 0}
  %{datapoint: :last_interval, function_time_spent: "Elixir.AnnotatedModule.annotated_function/0", value: 4541}
  %{datapoint: :total, function_time_spent: "Elixir.AnnotatedModule.annotated_function/0", value: 4541}
  ```
  """

  defmacro __using__(_options) do
    quote do
      InstrumentedFunctionList.track_module(__MODULE__)
      @before_compile Alchemetrics.Annotation
      @on_definition Alchemetrics.Annotation
    end
  end

  def __on_definition__(env, kind, name, args, guards, body) do
    if !is_nil(body) do
      function = Alchemetrics.Annotation.Function.new(env, kind, name, args, guards, body)
      if Function.has_metric_tag?(function) || Function.similar_functions_marked_for_instrumentation?(function) do
        Function.mark_for_instrumentation(function)
      end
    end
  end

  defmacro __before_compile__(env) do
    functions_in_ast_format =
    InstrumentedFunctionList.get_all(env.module)
    |> Enum.reverse
    |> Enum.map(fn(%Function{} = function) ->
      function
      |> Function.inject_code_in_the_begining(quote do
        function = unquote(Macro.escape(function))
        alchemetrics_internal_function_call_start_time__ = System.monotonic_time()
        alchemetrics_internal_function_name__ = "#{function.module}.#{function.name}/#{function.arity}"
        Alchemetrics.increment(function_calls: alchemetrics_internal_function_name__)
      end)
      |> Function.inject_code_in_the_end(quote do
        alchemetrics_internal_function_call_end_time__ =
          (System.monotonic_time() - alchemetrics_internal_function_call_start_time__)
          |> System.convert_time_unit(:native, :micro_seconds)
          |> Alchemetrics.report(function_time_spent: alchemetrics_internal_function_name__)
      end)
      |> Function.transform_to_ast
    end)

    quote do
      unquote_splicing(functions_in_ast_format)
    end
  end
end
