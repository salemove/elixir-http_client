defmodule Salemove.HttpClient.Middleware.MapHeaders do
  @behaviour Tesla.Middleware

  @moduledoc """
  Allows headers to be a map instead of a list.
  """

  def call(%Tesla.Env{headers: headers} = env, next, _) when is_map(headers) do
    headers_list = Map.to_list(headers)
    env = %Tesla.Env{env | headers: headers_list}
    Tesla.run(env, next)
  end

  def call(env, next, _) do
    Tesla.run(env, next)
  end
end
