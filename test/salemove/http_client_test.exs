defmodule Salemove.HttpClientTest do
  use Salemove.HttpClientCase

  alias Salemove.HttpClient

  defmodule TestClient do
    use Salemove.HttpClient,
      base_url: "http://test-api/",
      headers: %{"X-Custom-Header" => "A value"},
      username: "user",
      password: "pass",
      stats: [backend: MockStats]
  end

  describe "sending HTTP request" do
    test "sends GET request to specified URL" do
      assert_sends_request_without_body(:get)
    end

    test "sends HEAD request to specified URL" do
      assert_sends_request_without_body(:head)
    end

    test "sends DELETE request to specified URL" do
      assert_sends_request_without_body(:delete)
    end

    test "sends POST request to specified URL" do
      assert_sends_request_with_json_encoded_body(:post)
    end

    test "sends PUT request to specified URL" do
      assert_sends_request_with_json_encoded_body(:put)
    end

    test "sends PATCH request to specified URL" do
      assert_sends_request_with_json_encoded_body(:patch)
    end

    defp assert_sends_request_without_body(verb) do
      response = %{"response" => "value"}

      allow_http_request(fn env ->
        env
        |> status(200)
        |> json(response)
      end)

      assert {:ok, %{body: ^response}} = apply(TestClient, verb, ["/test"])
      assert_requested(env)

      assert "A value" = Tesla.get_header(env, "X-Custom-Header")
      assert "Basic " <> auth = Tesla.get_header(env, "authorization")
      assert auth == Base.encode64("user:pass")
      assert env.url == "http://test-api/test"
      assert env.method == verb
    end

    defp assert_sends_request_with_json_encoded_body(verb) do
      request = %{"key" => "value"}
      response = %{"response" => "value"}

      allow_http_request(fn env ->
        env
        |> status(200)
        |> json(response)
      end)

      assert {:ok, %{body: ^response}} = apply(TestClient, verb, ["/test", request])
      assert_requested(env)

      assert "A value" = Tesla.get_header(env, "X-Custom-Header")
      assert "Basic " <> auth = Tesla.get_header(env, "authorization")

      assert env.url == "http://test-api/test"
      assert auth == Base.encode64("user:pass")
      assert env.method == verb
      assert env.body == Jason.encode!(request)
    end
  end

  describe "catching connection errors" do
    alias HttpClient.ConnectionError

    defmodule Counter do
      def start_link do
        Agent.start_link(fn -> 0 end)
      end

      def get_and_increment(counter) do
        Agent.get_and_update(counter, fn current -> {current, current + 1} end)
      end
    end

    @tag capture_log: true
    test "returns {:error, %ConnectionError{}} when adapter throws an error" do
      error_reason = :econnrefused

      allow_http_request(fn _env ->
        {:error, error_reason}
      end)

      assert {:error, error} = TestClient.get("/test")
      assert %ConnectionError{reason: ^error_reason} = error
    end

    @tag capture_log: true
    test "retries if connection was refused and `:retry` option is on" do
      {:ok, counter} = Counter.start_link()

      error_reason = :econnrefused

      normal_response = %{"response" => "value"}

      self_pid = self()

      allow_http_request(fn env ->
        if Counter.get_and_increment(counter) > 1 do
          env
          |> status(200)
          |> json(normal_response)
        else
          send(self_pid, :connection_refused_received)

          {:error, error_reason}
        end
      end)

      assert {:ok, %{body: ^normal_response}} = TestClient.get("/", retry: [delay: 10])

      assert_received :connection_refused_received
      assert_received :connection_refused_received
    end
  end

  describe "interpreting server response" do
    setup context do
      body = context[:body] || %{"response" => "value"}
      status = context[:status] || 200

      allow_http_request(fn env ->
        env
        |> status(status)
        |> json(body)
      end)

      :ok
    end

    alias HttpClient.Response
    alias HttpClient.JSONError
    alias HttpClient.UnexpectedRedirectError
    alias HttpClient.ClientError
    alias HttpClient.ServerError
    alias HttpClient.UnavailableError
    alias HttpClient.UnsupportedProtocolError

    @body %{"response" => "value"}
    @tag status: 200, body: @body
    test "returns {:ok, Response.t} if server responds with 200" do
      assert {:ok, %Response{body: @body, status: 200}} = TestClient.get("/test")
    end

    test "returns {:error, %JSONError{}} if server returns malformed JSON" do
      allow_http_request(fn env ->
        env
        |> status(200)
        |> body("{asdf")
        |> header("content-type", "application/json")
      end)

      assert {:error, %JSONError{}} = TestClient.get("/test")
    end

    @tag status: 101, capture_log: true
    test "returns {:error, %UnsupportedProtocolError{}} if server responds with 3xx" do
      assert {:error, %UnsupportedProtocolError{}} = TestClient.get("/test")
    end

    @tag status: 302, capture_log: true
    test "returns {:error, %UnexpectedRedirectError{}} if server responds with 3xx" do
      assert {:error, %UnexpectedRedirectError{}} = TestClient.get("/test")
    end

    @tag status: 404, body: %{message: "Resource not found"}, capture_log: true
    test "returns {:error, %ClientError{}} if server responds with 404" do
      assert {:error, %ClientError{body: %{"message" => "Resource not found"}}} = TestClient.get("/test")
    end

    @tag status: 500, capture_log: true
    test "returns {:error, %ServerError{}} if server responds with 500" do
      assert {:error, %ServerError{}} = TestClient.get("/test")
    end

    @tag status: 503, capture_log: true
    test "returns {:error, %UnavailableError{}} if server responds with 502..Infinity" do
      assert {:error, %UnavailableError{}} = TestClient.get("/test")
    end
  end
end
