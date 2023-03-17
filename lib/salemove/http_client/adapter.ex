defmodule Salemove.HttpClient.Adapter do
  @moduledoc """
  Custom Tesla adapter which allows to specify adapter in request options.
  It also allows configuring adapter at runtime, using, for example, environment variables.

  ## Example

      Salemove.HttpClient.request(url: "http://www.google.com/", method: :get, adapter: Tesla.Adapter.Hackney)
  """

  @doc false
  def call(%{opts: opts} = env, _opts) do
    adapter = Keyword.fetch!(opts, :__adapter)
    adapter_options = Keyword.get(opts, :__adapter_options, [])

    adapter.call(env, adapter_options)
  end
end
