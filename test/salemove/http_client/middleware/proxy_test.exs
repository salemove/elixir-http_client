defmodule Salemove.HttpClient.Middleware.ProxyTest do
  use Salemove.HttpClientCase, async: false

  alias Salemove.HttpClient

  defmodule DefaultClient do
    use Salemove.HttpClient, base_url: "http://test-api/"
  end

  setup do
    allow_http_request(fn env ->
      env
      |> status(200)
      |> json(%{})
    end)

    on_exit(fn ->
      System.delete_env("HTTP_PROXY")
      System.delete_env("HTTPS_PROXY")
      System.delete_env("NO_PROXY")
    end)
  end

  describe "when client configured proxy on module level" do
    defmodule ProxyClient do
      use Salemove.HttpClient,
        base_url: "http://test-api/",
        proxy: "http://127.0.0.1:3128/"
    end

    test "sends requests through HTTP proxy" do
      {:ok, _} = ProxyClient.get("/test")
      assert_requested(env)

      assert env.opts[:adapter_options][:proxy] == "http://127.0.0.1:3128/"
    end
  end

  describe "when client configured proxy via environment variables" do
    @http_proxy "http://127.0.0.1:3128/"
    @https_proxy "https://127.0.0.1:3128/"

    test "doesn't use proxy by default" do
      env = get("/test")
      assert is_nil(env.opts[:adapter_options][:proxy])
    end

    test "uses proxy from HTTP_PROXY environment variable when protocol is HTTP" do
      System.put_env("HTTP_PROXY", @http_proxy)
      System.put_env("HTTPS_PROXY", @https_proxy)

      env = get("/test")
      assert env.opts[:adapter_options][:proxy] == @http_proxy
    end

    test "uses proxy from HTTPS_PROXY environment variable when protocol is HTTPS" do
      System.put_env("HTTP_PROXY", @http_proxy)
      System.put_env("HTTPS_PROXY", @https_proxy)

      env = get("https://test-api/test")
      assert env.opts[:adapter_options][:proxy] == @https_proxy
    end

    test "ignores proxy when the host is included into NO_PROXY environment variable" do
      System.put_env("HTTP_PROXY", @http_proxy)
      System.put_env("HTTPS_PROXY", @https_proxy)
      System.put_env("NO_PROXY", "localhost,.test-api")

      env = get("https://test-api/test")
      assert is_nil(env.opts[:adapter_options][:proxy])

      env = get("http://localhost/test")
      assert is_nil(env.opts[:adapter_options][:proxy])

      env = get("http://example.com/test")
      assert env.opts[:adapter_options][:proxy] == @http_proxy
    end

    defp get(url) do
      {:ok, _} = DefaultClient.get(url)
      assert_requested(env)

      env
    end
  end
end
