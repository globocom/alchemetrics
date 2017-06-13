defmodule ElixirMetrics.Function do
  alias ElixirMetrics.InstrumentedFunctionList
  alias ElixirMetrics.Function

  defstruct [:env, :module, :kind, :name, :arity, :args, :guards, :body]

  @metric_tag :metric

  def new(env, kind, name, args, guards, body) do
    %Function{
     env: env,
     module: env.module,
     kind: kind,
     name: name,
     arity: length(args),
     args: args,
     guards: guards,
     body: body
   }
  end

  def has_metric_tag?(%Function{} = function) do
    case Module.get_attribute(function.module, @metric_tag) do
      nil -> false
      _ -> true ## TODO: CHECK IF IS A VALID MARK
    end
  end

  def similar_functions_marked_for_instrumentation?(%Function{} = function) do
    InstrumentedFunctionList.contains_similar?(function)
  end

  def mark_for_instrumentation(%Function{} = function) do
    if(!InstrumentedFunctionList.contains?(function)) do
      InstrumentedFunctionList.save_one(function)
    end
    Module.delete_attribute(function.module, @metric_tag)
  end

  def transform_to_ast(%Function{} = function) do
    if is_public?(function) do
      make_overridable(function)
      recreate_function(function)
    end
  end

  def inject_code_in_the_begining(%Function{} = function, code_to_inject) do
    new_body = quote do
      unquote(code_to_inject)
      unquote(function.body)
    end
    override_body(function, new_body)
  end

  def inject_code_in_the_end(%Function{} = function, code_to_inject) do
    new_body = quote do
      return_value = unquote(function.body)
      unquote(code_to_inject)
      return_value
    end
    override_body(function, new_body)
  end

  def inject_code_before_and_after_body(%Function{} = function, before_code, after_code) do
    new_body = quote do
      unquote(before_code)
      return_value = unquote(function.body)
      unquote(after_code)
      return_value
    end
    override_body(function, new_body)
  end

  defp is_public?(%Function{} = function) do
    function.kind == :def
  end

  defp make_overridable(%Function{} = function) do
    if !Module.overridable?(function.module, {function.name, function.arity}) do
      Module.make_overridable(function.module, [{function.name, function.arity}])
    end
  end

  defp recreate_function(%Function{} = function) do
    case function.guards do
      [] ->
        recreate_without_guard_clauses(function)
      _guards ->
        recreate_with_guard_clauses(function)
    end
  end

  defp recreate_without_guard_clauses(%Function{} = function) do
    quote do
      # Recreating function signature: def name(param1, param2...) do
      def unquote(function.name)(unquote_splicing(function.args))  do
        unquote(function.body)
      end
    end
  end

  defp recreate_with_guard_clauses(%Function{} = function) do
    quote do
      # Same as before but with guard clauses
      def unquote(function.name)(unquote_splicing(function.args)) when unquote_splicing(function.guards) do
        unquote(function.body)
      end
    end
  end

  defp override_body(%Function{} = function, new_body) do
    %Function{function | body: new_body}
  end
end
