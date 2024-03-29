 defmodule Alchemetrics.Mixfile do
  use Mix.Project

  @description """
  Alchemetrics is a wrapper around exometer, that uses GenStage to backpressure the reports.
  """

  @project_url "https://github.com/globocom/alchemetrics"

  def project do
    [
      app: :alchemetrics,
      version: "0.5.2",
      elixir: "~> 1.12.2",
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: @description,
      source_url: @project_url,
      homepage_url: @project_url,
      package: package(),
      test_coverage: [tool: ExCoveralls],
      name: "Alchemetrics",
      docs: [
        main: "api-reference",
        source_url: @project_url
      ],
      deps: deps(),
   ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :exometer_core],
     mod: {Alchemetrics.Application, []}]
  end

  # Specifies which paths to compile per environment.

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:gen_stage, "~> 1.1"},
      {:exometer_core, "~> 1.6"},
      {:ex_doc, "~> 0.25.3", only: :dev},
      {:mock, "~> 0.3.7", only: :test},
      {:excoveralls, "~> 0.14.3", only: :test}
    ]
  end

  defp package do
    [files: ["config", "lib", "mix.exs", "mix.lock", "README.md", "LICENSE"],
     maintainers: ["Globo.com"],
     licenses: ["MIT"],
     links: %{"GitHub" => @project_url},]
  end
end
