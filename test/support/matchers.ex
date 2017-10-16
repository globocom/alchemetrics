defmodule Matchers do
  def close_to(expected_value), do: close_to(expected_value, accepted_variation: 0.05)
  def close_to(expected_value, [accepted_variation: variation]) do
    :meck.is(fn(value) -> value >= expected_value*(1-variation) and value <= expected_value*(1+variation) end)
  end
end
