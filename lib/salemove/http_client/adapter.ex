defmodule Salemove.HttpClient.Adapter do
  @moduledoc """
  Custom Tesla adapter which allows to specify adapter in request options.
  It also allows configuring adapter at runtime, using, for example, environment variables.

  ## Example

      Salemove.HttpClient.request(url: "http://www.google.com/", method: :get, adapter: :hackney)
  """

  @doc false
  # executed as middleware
  def call(env, next, opts) do
    env
    |> Tesla.put_opt(:__adapter, Keyword.fetch!(opts, :adapter))
    |> Tesla.put_opt(:__adapter_options, Keyword.get(opts, :adapter_options, []))
    |> Tesla.run(next)
  end

  @doc false
  # executed as adapter
  def call(%{opts: opts} = env, _opts) do
    adapter = opts |> Keyword.fetch!(:__adapter) |> Tesla.alias()
    adapter_options = Keyword.get(opts, :__adapter_options, [])

    adapter.call(env, adapter_options)
  end
end
