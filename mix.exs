defmodule Salemove.HttpClient.Mixfile do
  use Mix.Project

  def project do
    [
      app: :salemove_http_client,
      version: "2.4.0",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      docs: [
        main: "Salemove.HttpClient",
        extras: ["CHANGELOG.md"]
      ],
      dialyzer: [
        plt_add_apps: [:ex_unit],
        flags: [:error_handling, :race_conditions, :underspecs]
      ]
    ]
  end

  def description do
    ~S"""
    Elixir HTTP client for JSON services
    """
  end

  def package do
    [
      maintainers: ["SaleMove TechMovers"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/salemove/elixir-http_client"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:tesla_statsd, "~> 0.4.0"},
      {:confex, "~> 3.0"},
      {:telemetry, "~> 0.4 or ~> 1.0"},
      {:opentelemetry_tesla, "~> 2.0", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:jason, "~> 1.1"}
    ]
  end
end
