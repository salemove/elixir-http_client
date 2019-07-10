defmodule Salemove.HttpClientCase do
  @moduledoc """
  This case template can be used to easily mock Tesla responses
  without messing up manually with `Tesla.Env` using helper
  `allow_http_request/1` and `assert_requested/2` macro.

  Client adapter must be set to `Tesla.Mock`.

  ## Example

      # in config/test.exs

      config :my_app, GithubClient,
        base_url: "https://api.github.com/",
        adapter: :mock

      defmodule GithubClient do
        use Salemove.HttpClient, Application.get_env(:my_app, __MODULE__)
      end

      defmodule GithubClientTest do
        use Salemove.HttpClientCase

        test "sends request" do
          allow_http_request fn env ->
            env
            |> status(200)
            |> json(%{status: "ok"})
          end

          assert {:ok, %Salemove.HttpClient.Response{body: response}} = GithubClient.get("/")

          assert_requested %{url: "https://api.github.com/"}
        end
      end
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Salemove.HttpClientCase
    end
  end

  @doc """
  Setup mock for the current test
  """
  def allow_http_request(mock_func) do
    Tesla.Mock.mock(fn env ->
      notify_calling_process(env)
      mock_func.(env)
    end)
  end

  @doc """
  Verify that previously set up HTTP mock has been called
  """
  defmacro assert_requested(pattern, timeout \\ 100)

  defmacro assert_requested({:when, _, [pattern, guard]}, timeout) do
    quote do
      assert_receive({:http_request, unquote(pattern)} when unquote(guard), unquote(timeout))
    end
  end

  defmacro assert_requested(pattern, timeout) do
    quote do
      assert_receive {:http_request, unquote(pattern)}, unquote(timeout)
    end
  end

  @doc """
  Set status for mocked response
  """
  def status(%Tesla.Env{} = env, status) do
    %{env | status: status}
  end

  @doc """
  Set body (as string) for mocked response
  """
  def body(%Tesla.Env{} = env, body) do
    %{env | body: body}
  end

  @doc """
  Set JSON body for mocked response
  """
  def json(%Tesla.Env{} = env, body) do
    env
    |> header("Content-Type", "application/json")
    |> body(Poison.encode!(body))
  end

  @doc """
  Add arbitrary header to the mocked response
  """
  def header(%Tesla.Env{} = env, name, value) do
    Tesla.put_header(env, name, value)
  end

  defp notify_calling_process(env) do
    send(self(), {:http_request, env})
    env
  end
end
