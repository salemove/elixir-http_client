defmodule Salemove.HttpClient.ConnectionError do
  @moduledoc "Indicates error on transport level"

  defexception [:message, :reason]

  @type t :: %__MODULE__{
          __exception__: true,
          message: String.t(),
          reason: any
        }
end

defmodule Salemove.HttpClient.JSONError do
  @moduledoc "An error that occurs when request/response body is not valid JSON"

  defexception [:message, :reason]

  @type t :: %__MODULE__{
          __exception__: true,
          message: String.t(),
          reason: any
        }
end

defmodule Salemove.HttpClient.InvalidResponseError do
  @moduledoc "A generic error that occurs when server responds with non-2xx status"

  @type t :: %{
          __exception__: true,
          message: String.t(),
          status: Tesla.Env.status(),
          body: Tesla.Env.body(),
          headers: Tesla.Env.headers()
        }

  defmacro __using__(message) do
    quote do
      @type t :: %__MODULE__{
              __exception__: true,
              message: String.t(),
              status: Tesla.Env.status(),
              body: Tesla.Env.body(),
              headers: Tesla.Env.headers()
            }

      defexception [:message, :status, :body, :headers]

      @doc "Create a new #{__MODULE__} struct from Tesla.Env"
      @spec new(Tesla.Env.t()) :: t
      def new(%Tesla.Env{} = env) do
        struct(%__MODULE__{message: unquote(message)}, Map.from_struct(env))
      end
    end
  end
end

defmodule Salemove.HttpClient.UnsupportedProtocolError do
  @moduledoc "An error that occurs when server responds with status < 200"

  use Salemove.HttpClient.InvalidResponseError, "Server response not supported"
end

defmodule Salemove.HttpClient.UnexpectedRedirectError do
  @moduledoc "An error that occurs when server responds with 3xx status"

  use Salemove.HttpClient.InvalidResponseError, "Server redirected"
end

defmodule Salemove.HttpClient.ClientError do
  @moduledoc "An error that occurs when server responds with 4xx status"

  use Salemove.HttpClient.InvalidResponseError, "Client error"
end

defmodule Salemove.HttpClient.ServerError do
  @moduledoc "An error that occurs when server responds with 500 or 501 status"

  use Salemove.HttpClient.InvalidResponseError, "Internal server error"
end

defmodule Salemove.HttpClient.UnavailableError do
  @moduledoc "An error that occurs when server responds any status > 501"

  use Salemove.HttpClient.InvalidResponseError, "Service unavailable"
end
