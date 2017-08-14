defmodule Alchemetrics.ConsoleReporter do
  use Alchemetrics.CustomReporter

  def init(options) do
    IO.puts "Starting #{__MODULE__} with following options: #{inspect options}"
    %{}
  end

  def report(public_name, metric, value, options) do
    IO.puts "Reporting: #{inspect %{name: public_name, metric: metric, value: value, options: options}}"
  end
end

