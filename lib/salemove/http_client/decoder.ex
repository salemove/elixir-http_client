defmodule Salemove.HttpClient.Decoder do
  @moduledoc """
  A module, responsible for creating a `EngagementRouter.HttpClient.Response`
  from `Tesla` response, or, if request wasn't successful, for creating one
  of exception structures.
  """

  alias Salemove.HttpClient.Response
  alias Salemove.HttpClient.JSONError
  alias Salemove.HttpClient.ConnectionError
  alias Salemove.HttpClient.InvalidResponseError
  alias Salemove.HttpClient.UnexpectedRedirectError
  alias Salemove.HttpClient.ClientError
  alias Salemove.HttpClient.ServerError
  alias Salemove.HttpClient.UnavailableError
  alias Salemove.HttpClient.UnsupportedProtocolError

  @type tesla_result :: {:ok, Tesla.Env.t()} | {:error, %Tesla.Error{}}
  @type on_decode :: {:ok, Response.t()} | {:error, InvalidResponseError.t()}

  @doc """
  Accepts result of request to `Tesla` client and constructs
  `#{Response}` structure from it.
  """
  @spec decode(tesla_result) :: on_decode
  def decode(tesla_result)

  def decode({:ok, %Tesla.Env{} = env}) do
    decode_env(env)
  end

  def decode({:error, %Tesla.Error{} = error}) do
    decode_error(error)
  end

  ##

  defp decode_env(%{status: status} = env) do
    cond do
      status in 200..299 -> {:ok, Response.new(env)}
      status in 300..399 -> {:error, UnexpectedRedirectError.new(env)}
      status in 400..499 -> {:error, ClientError.new(env)}
      status in 500..501 -> {:error, ServerError.new(env)}
      status > 501 -> {:error, UnavailableError.new(env)}
      true -> {:error, UnsupportedProtocolError.new(env)}
    end
  end

  defp decode_error(%Tesla.Error{message: "JSON " <> _ = message, reason: reason}) do
    {:error, %JSONError{message: message, reason: reason}}
  end

  defp decode_error(%Tesla.Error{message: message, reason: reason}) do
    {:error, %ConnectionError{message: message, reason: reason}}
  end
end
