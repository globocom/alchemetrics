 defmodule Alchemetrics.Mixfile do
  use Mix.Project

  @description """
  Alchemetrics is a wrapper around exometer, that uses GenStage to backpressure the reports.
  """

  @project_url "https://github.com/globocom/alchemetrics"

  def project do
    [
      app: :alchemetrics,
      version: "0.2.3",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: @description,
      source_url: @project_url,
      homepage_url: @project_url,
      package: package(),
      test_coverage: [tool: ExCoveralls],
      name: "Alchemetrics",
      docs: [
        main: "Alchemetrics",
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
      {:gen_stage, "~> 0.11"},
      {:plug, "~> 1.3"},
      {:exometer_core, "~> 1.0", hex: :basho_exometer_core},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:excoveralls, "~> 0.7", only: :test}
    ]
  end

  defp package do
    [files: ["config", "lib", "mix.exs", "mix.lock", "README.md", "LICENSE"],
     maintainers: ["Globo.com"],
     licenses: ["MIT"],
     links: %{"GitHub" => @project_url},]
  end
end
