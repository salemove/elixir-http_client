# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

config :logger, level: :warning

config :salemove_http_client, adapter: Tesla.Mock
