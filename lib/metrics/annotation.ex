defmodule Metrics.Annotation do
  alias Metrics.InstrumentedFunctionList
  alias Metrics.Function

  # Example
  # @metric scope: "gen_stage", type: "discarded", measure: [:function_calls, :function_time]
  # @metric scope: "gen_stage", type: "discarded", measure: [:function_calls, :function_time]

  defmacro __using__(_options) do
    quote do
      InstrumentedFunctionList.track_module(__MODULE__)
      @before_compile Metrics.Annotation
      @on_definition Metrics.Annotation
    end
  end

  def __on_definition__(env, kind, name, args, guards, body) do
    function = Metrics.Function.new(env, kind, name, args, guards, body)
    if Function.has_metric_tag?(function) || Function.similar_functions_marked_for_instrumentation?(function) do
      Function.mark_for_instrumentation(function)
    end
  end

  defmacro __before_compile__(env) do
    functions_in_ast_format =
    InstrumentedFunctionList.get_all(env.module)
    |> Enum.reverse
    |> Enum.map(fn(%Function{} = function) ->
      function
      |> Function.inject_code_in_the_begining(quote do IO.puts("AAAA") end)
      |> Function.inject_code_in_the_end(quote do IO.puts("BBBB") end)
      |> Function.transform_to_ast
    end)

    quote do
      unquote_splicing(functions_in_ast_format)
    end
  end
end
