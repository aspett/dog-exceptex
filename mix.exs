defmodule DogExceptex.MixProject do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :dog_exceptex,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      docs: docs(),
      package: package(),
      deps: deps(),
      description: "Logger backend for Datadog"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:dogstatsd, "~> 0.0"},
      {:accessible, "~> 0.2"}
    ]
  end

  defp package do
    [maintainers: ["Andrew Pett"],
     licenses: ["MIT"],
     links: %{"Github": "https://github.com/aspett/dog-exceptex"}]
  end

  defp docs do
    [extras: ["README.md"],
     source_url: "https://github.com/aspett/dog-exceptex",
     assets: "assets",
     main: "readme",
     source_ref: @version]
  end
end
