defmodule Blitzurgist.MixProject do
  use Mix.Project

  def project do
    [
      app: :blitzurgist,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: dialyzer(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :wx, :observer, :runtime_tools],
      mod: {Blitzurgist, []}
    ]
  end

  defp deps do
    [
      {:req, "~> 0.4.11"},
      {:gen_stage, "~> 1.0"},
      {:dialyxir, "~> 1.4.3", only: [:dev, :test], runtime: false}
    ]
  end

  defp dialyzer() do
    [
      plt_add_deps: :app_tree,
      plt_add_apps: ~w(ex_unit mix)a,
      ignore_warnings: ".dialyzer-ignore",
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
