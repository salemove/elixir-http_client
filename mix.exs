defmodule Salemove.HttpClient.Mixfile do
  use Mix.Project

  def project do
    [
      app: :salemove_http_client,
      version: "1.0.2",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      docs: [
        main: "Salemove.HttpClient"
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.0"},
      {:tesla_statsd, "~> 0.3.0"},
      {:confex, "~> 3.0"},
      {:ex_statsd, ">= 0.0.0", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:tesla_middleware_tapper, "~> 0.2.0", optional: true},
      {:jason, "~> 1.1"},
      {:deep_merge, "~> 1.0"}
    ]
  end
end
