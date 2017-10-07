defmodule Alchemetrics.Annotation do
  alias Alchemetrics.Annotation.InstrumentedFunctionList
  alias Alchemetrics.Annotation.Function

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
