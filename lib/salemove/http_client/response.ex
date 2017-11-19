defmodule Salemove.HttpClient.Response do
  @moduledoc """
  A generic HTTP client response. Contains response headers, status and body.

  Specific clients must implement their own response handling logic.
  """

  @type t :: %__MODULE__{
          status: Tesla.Env.status(),
          headers: Tesla.Env.headers(),
          body: Tesla.Env.body()
        }

  defstruct [:status, :headers, :body]

  @doc """
  Create new #{__MODULE__} struct from Tesla response
  """
  @spec new(Tesla.Env.t()) :: t
  def new(%Tesla.Env{} = env) do
    struct(__MODULE__, Map.from_struct(env))
  end
end
