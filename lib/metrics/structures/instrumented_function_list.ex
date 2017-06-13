defmodule ElixirMetrics.InstrumentedFunctionList do
  @function_list_tag :instrumented_functions

  alias ElixirMetrics.Function

  def track_module(module) do
    Module.register_attribute(module, @function_list_tag, accumulate: true)
  end

  def save_one(%Function{} = function) do
    Module.put_attribute(function.module, @function_list_tag, function)
  end

  def get_all(module) do
    Module.get_attribute(module, @function_list_tag)
  end

  def contains_similar?(%Function{} = function) do
    get_all(function.module)
    |> function_with_same_name_and_arity?(function.name, function.arity)
  end

  def contains?(%Function{} = function) do
    get_all(function.module)
    |> function_instrumented?(function)
  end

  defp function_with_same_name_and_arity?([], _name, _arity), do: false
  defp function_with_same_name_and_arity?([fun|function_list], name, arity) do
    if(fun.name == name && fun.arity == arity) do
      true
    else
      function_with_same_name_and_arity?(function_list, name, arity)
    end
  end

  defp function_instrumented?([], _function), do: false
  defp function_instrumented?([fun|_], %Function{} = function) do
    if(fun == function) do
      true
    else
      false
    end
  end
end
