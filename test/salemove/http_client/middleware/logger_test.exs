defmodule Salemove.HttpClient.Middleware.LoggerTest do
  use ExUnit.Case, async: false

  defmodule Client do
    use Tesla

    @base_url "https://base.url"

    plug(Tesla.Middleware.BaseUrl, @base_url)

    plug(
      Salemove.HttpClient.Middleware.Logger,
      level: %{
        422 => :info,
        (410..418) => :warning
      }
    )

    adapter fn env ->
      case env.url do
        "#{@base_url}/connection-error" ->
          {:error, %Tesla.Error{env: env, reason: :econnrefused}}

        "#{@base_url}/timeout" ->
          {:error, :timeout}

        "#{@base_url}/closed" ->
          {:error, :closed}

        "#{@base_url}/unexpected-error" ->
          {:error, "unexpected error"}

        _ ->
          {status, body} =
            case env.url do
              "#{@base_url}/server-error" ->
                {500, "error"}

              "#{@base_url}/client-error" ->
                {404, "error"}

              "#{@base_url}/teapot" ->
                {418, "i am a teapot"}

              "#{@base_url}/unprocessable-entity" ->
                {422, "error"}

              "#{@base_url}/redirect" ->
                {301, "moved"}

              "#{@base_url}/ok" ->
                {200, "ok"}
            end

          {:ok, %{env | status: status, headers: [{"content-type", "text/plain"}], body: body}}
      end
    end
  end

  import ExUnit.CaptureLog

  setup do
    level_before = Logger.level()

    Logger.configure(level: :info)

    on_exit(fn ->
      Logger.configure(level: level_before)
    end)
  end

  @format "[$level] $message $metadata\n"
  @metadata [:method, :path, :duration_ms, :status, :url]

  @logger_opts [format: @format, metadata: @metadata]

  test "connection error" do
    log =
      capture_log(@logger_opts, fn ->
        assert {:error, %Tesla.Error{}} = Client.get("/connection-error")
      end)

    assert log =~ "/connection-error -> :econnrefused"
    assert log =~ ~r/status=:econnrefused/
  end

  test "timeout" do
    log = capture_log(@logger_opts, fn -> Client.get("/timeout") end)
    assert log =~ "/timeout -> :timeout"
    assert log =~ ~r/\[warn(ing)?\]/
    assert log =~ ~r/status=timeout/
  end

  test "closed" do
    log = capture_log(@logger_opts, fn -> Client.get("/closed") end)
    assert log =~ "/closed -> :closed"
    assert log =~ ~r/\[warn(ing)?\]/
    assert log =~ ~r/status=closed/
  end

  test "server error" do
    log = capture_log(fn -> Client.get("/server-error") end)
    assert log =~ "/server-error -> 500"
    assert log =~ ~r/\[warn(ing)?\]/
  end

  test "client error" do
    log = capture_log(fn -> Client.get("/client-error") end)
    assert log =~ "/client-error -> 404"
  end

  test "client error with custom log level option" do
    log = capture_log(fn -> Client.get("/unprocessable-entity") end)
    assert log =~ "/unprocessable-entity -> 422"
    assert log =~ "info"
  end

  test "client error with custom log level option supplied as range" do
    log = capture_log(fn -> Client.get("/teapot") end)
    assert log =~ "/teapot -> 418"
    assert log =~ ~r/\[warn(ing)?\]/
  end

  test "unexpected error" do
    log = capture_log(@logger_opts, fn -> Client.get("/unexpected-error") end)
    assert log =~ "/unexpected-error -> \"unexpected error\""
    assert log =~ "[error]"
    assert log =~ ~r/status="unexpected error"/
  end

  test "redirect" do
    log = capture_log(fn -> Client.get("/redirect") end)
    assert log =~ "/redirect -> 301"
  end

  test "ok" do
    log = capture_log(fn -> Client.get("/ok") end)
    assert log =~ "/ok -> 200"
  end

  test "metadata is included in the log" do
    log = capture_log(@logger_opts, fn -> Client.get("/ok") end)

    assert log =~ ~r/url=https:\/\/base.url\/ok/
    assert log =~ ~r/path=\/ok/
    assert log =~ ~r/status=200/
    assert log =~ ~r/method=GET/
    assert log =~ ~r/duration_ms=\d\.\d{3}/
  end
end
