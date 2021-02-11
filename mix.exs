defmodule CiAutomaticTestTimingSplitter.MixProject do
  use Mix.Project

  def project do
    [
      app: :ci_automatic_test_timing_splitter,
      version: "0.1.0",
      elixir: "~> 1.11",
      deps: deps(),
      escript: escript()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp escript do
    [main_module: CiAutomaticTestTimingSplitter]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:sweet_xml, "~> 0.6.6"},
      {:table_rex, "~> 3.1.1"}
    ]
  end
end
