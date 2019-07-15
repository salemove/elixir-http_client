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

## License

MIT License, Copyright (c) 2017 SaleMove
