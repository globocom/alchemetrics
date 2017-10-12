defmodule FakeAnnotatedModule do
  use Alchemetrics.Annotation

  @alchemetrics instrument_function: true
  def annotated_function, do: nil

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
