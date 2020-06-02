# Salemove.HttpClient

[![Build Status](https://travis-ci.org/salemove/elixir-http_client.svg?branch=add-support-for-global-config)](https://travis-ci.org/salemove/elixir-http_client)
[![Hex.pm](https://img.shields.io/hexpm/v/salemove_http_client.svg)](https://hex.pm/packages/salemove_http_client)
[![Documentation](https://img.shields.io/badge/Documentation-online-green.svg)](http://hexdocs.pm/salemove_http_client)

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
      base_url: "https://api.github.com/"
end
```

## Migrating from 0.x to 1.0

Most changes are due to changes in Tesla HTTP client. Migrating guide for tesla can be seen at https://github.com/teamon/tesla/wiki/0.x-to-1.0-Migration-Guide.

### Changes specific to Salemove HTTP Client
* `Salemove.HttpClient.ConnectionError` struct no longer has a field `message`. The error message can be fetched using `Exception.message/1`.

## Migrating from 1.x to 2.0

Module config is now deep merged with base salemove_http_client config, so when upgrading, make sure that calls to Salemove HTTP Client don't rely on the configuration being shallow merged.

### Example

```elixir
config :foo, Some.Module,
  adapter_options: [
    connect_timeout: 8000
]

config :salemove_http_client,
adapter_options: [
  ssl_options: [verify: :verify_none]
]
```

and as a result of

```elixir
use Salemove.HttpClient, Application.fetch_env!(:foo, Some.Module)
```

with the older version the configuration would have been:

```elixir
adapter_options: [
  connect_timeout: 8000
]
```

with 2.x and upwards it is:

```elixir
adapter_options: [
  ssl_options: [verify: :verify_none],
  connect_timeout: 8000
]
```

To disable stats now, you can just set `stats` value to `false` in the module configuration.


## License

MIT License, Copyright (c) 2017 SaleMove
