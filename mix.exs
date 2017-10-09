defmodule Sundog.Mixfile do
  use Mix.Project

  def project do
    [
      app: :sundog,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Sundog, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:mix_test_watch, "~> 0.3", only: :dev, runtime: false},
      {:httpoison, "~> 0.13"},
      {:timex, "~> 3.1"},
      {:poison, "~> 3.1"},
      {:memoize, "~> 1.2"},
      {:mock, "~> 0.2.0", only: :test},
      {:exvcr, "~> 0.8", only: [:dev, :test]},
      {:briefly, "~> 0.3", only: :test},

      # Fix https://github.com/bitwalker/distillery/issues/321
      {:distillery, git: "https://github.com/bitwalker/distillery.git",
        ref: "4c154e013a27d9f82d8cff147309674eb41e3db4", runtime: false},
    ]
  end
end
