# Salemove.HttpClient

Elixir HTTP client for JSON services built on top of [tesla](https://github.com/teamon/tesla).

## Installation

The package can be installed by adding `salemove_http_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:salemove_http_client, "~> 0.1.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/salemove_http_client](https://hexdocs.pm/salemove_http_client).

## Usage

```elixir
defmodule GihubClient do
  use Salemove.HttpClient, 
      base_url: "https://api.github.com/",
      debug: Mix.env == :dev
end
```

## License

MIT License, Copyright (c) 2017 SaleMove
