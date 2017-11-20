defmodule Salemove.HttpClient do
  @moduledoc """
  Generic HTTP client built on top of Tesla and used to build specific JSON API HTTP clients
  with ability to configure them during runtime, using, for example, environment variables.

  ## Example

      defmodule Github do
        use Salemove.HttpClient, base_url: "https://api.github.com/"

        def user_repos(login, opts \\ []) do
          get("/user/" <> login <> "/repos", opts)
        end
      end

      Github.user_repos("take-five")

  ## Configuration options

  There are number of available configuration options:

    * `:base_url` - Base URL of service (including schema, i.e. `https://api.github.com/`)
    * `:adapter` - HTTP Adapter module, defaults to `Tesla.Adapter.Hackney`
    * `:adapter_options` - adapter specific options, see documentation for concrete adapter
    * `:json` - JSON encoding/decoding options. See `Tesla.Middleware.JSON`.
    * `:stats` - StatsD instrumenting options. See `Tesla.StatsD` for more details.
    * `:username` - along with `:password` option adds basic authentication to all requests.
      See `Tesla.Middleware.BasicAuth`.
    * `:password` - see `:username`.
    * `:debug` - Turn on/off verbose request/response logging, defaults to `false`

  HTTP client can be configured at runtime and at compile time via configuration files. Note,
  that you can use `{:system, env_name}` tuples to configure the client

  ### Configuration via request options

  You can pass additional `Keyword` argument to request functions:

      Github.user_repos("take-five", adapter: :mock, base_url: "http://mocked-gh/")

  ### Configuration via config files

  In `config/config.exs`:

      config :salemove_http_client,
        adapter: :mock,
        base_url: "http://mocked-gh/"
  """

  @http_verbs ~w(head get delete trace options post put patch)a

  defmacro __using__(defaults_options \\ []) do
    friendly_api = Enum.map(@http_verbs, &generate_http_verb/1)

    quote do
      alias Salemove.HttpClient

      @type url :: HttpClient.url()
      @type body :: HttpClient.body()
      @type options :: HttpClient.options()
      @type response :: HttpClient.response()

      @doc false
      @spec request(options) :: response
      def request(options) do
        unquote(defaults_options)
        |> Keyword.merge(options)
        |> HttpClient.perform_request()
      end

      unquote(friendly_api)
    end
  end

  @hardcoded_defaults [
    adapter: Tesla.Adapter.Hackney,
    adapter_options: [
      connect_timeout: 1500,
      recv_timeout: 4500
    ],
    debug: false
  ]
  @application_defaults Keyword.merge(@hardcoded_defaults, Application.get_all_env(:salemove_http_client) || [])

  use Tesla,
    # don't generate GET/POST/... functions for HttpClient module
    only: [],
    # don't generate specs as they don't work well with Tesla.Middleware.Tuples
    docs: false

  adapter Salemove.HttpClient.Adapter

  alias Salemove.HttpClient.Decoder

  @typedoc "Client or request-specific options"
  @type options :: Keyword.t()
  @type response :: Decoder.on_decode()
  @type url :: Tesla.Env.url()
  @type body :: Tesla.Env.body()

  @doc false
  @spec perform_request(options) :: response
  def perform_request(options) do
    options = Confex.Resolver.resolve!(options)

    options
    |> build_client()
    |> request(options)
    |> Decoder.decode()
  end

  defp build_client(options) do
    @application_defaults
    |> Keyword.merge(options)
    |> Confex.Resolver.resolve!()
    |> build_stack()
    |> Tesla.build_client()
  end

  defp build_stack(options) do
    []
    |> push_middleware(Tesla.Middleware.Tuples)
    |> push_middleware({Tesla.StatsD, options[:stats]})
    |> push_middleware({Tesla.Middleware.BaseUrl, Keyword.fetch!(options, :base_url)})
    |> push_middleware({Tesla.Middleware.JSON, options[:json]})
    |> push_middleware(
         {Tesla.Middleware.BasicAuth, options},
         if: options[:username] && options[:password]
       )
    |> push_middleware(Tesla.Middleware.Logger)
    |> push_middleware(Tesla.Middleware.DebugLogger, if: options[:debug])
    |> push_middleware({__MODULE__.Adapter, options})
    |> Enum.reverse()
  end

  defp push_middleware(stack, middleware, [if: condition] \\ [if: true]) do
    if condition do
      [middleware | stack]
    else
      stack
    end
  end

  defp generate_http_verb(verb) when verb in [:post, :put, :patch] do
    quote do
      @doc """
      Perform a #{unquote(verb |> to_string() |> String.upcase())} request.
      See `HttpClient.request/2` for available options.
      """
      @spec unquote(verb)(url, body, options) :: response
      def unquote(verb)(url, body, options \\ []) do
        options
        |> Keyword.merge(url: url, body: body, method: unquote(verb))
        |> request()
      end
    end
  end

  defp generate_http_verb(verb) do
    quote do
      @doc """
      Perform a #{unquote(verb |> to_string() |> String.upcase())} request.
      See `HttpClient.request/2` for available options.
      """
      @spec unquote(verb)(url, options) :: response
      def unquote(verb)(url, options \\ []) do
        options
        |> Keyword.merge(url: url, method: unquote(verb))
        |> request()
      end
    end
  end
end
