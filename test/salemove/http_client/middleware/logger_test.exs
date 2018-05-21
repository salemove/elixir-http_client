defmodule Salemove.HttpClient.Middleware.LoggerTest do
  use ExUnit.Case, async: false

  defmodule Client do
    use Tesla

    plug(
      Salemove.HttpClient.Middleware.Logger,
      level: %{
        422 => :info,
        (410..418) => :warn
      }
    )

    adapter fn env ->
      {status, body} =
        case env.url do
          "/connection-error" ->
            raise %Tesla.Error{message: "adapter error: :econnrefused", reason: :econnrefused}

          "/server-error" ->
            {500, "error"}

          "/client-error" ->
            {404, "error"}

          "/teapot" ->
            {418, "i am a teapot"}

          "/unprocessable-entity" ->
            {422, "error"}

          "/redirect" ->
            {301, "moved"}

          "/ok" ->
            {200, "ok"}
        end

      %{env | status: status, headers: %{"content-type" => "text/plain"}, body: body}
    end
  end

  import ExUnit.CaptureLog

  setup do
    Logger.configure(level: :info)
  end

  test "connection error" do
    log =
      capture_log(fn ->
        assert_raise Tesla.Error, fn -> Client.get("/connection-error") end
      end)

    assert log =~ "/connection-error -> adapter error: :econnrefused"
  end

  test "server error" do
    log = capture_log(fn -> Client.get("/server-error") end)
    assert log =~ "/server-error -> 500"
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
    assert log =~ "warn"
  end

  test "redirect" do
    log = capture_log(fn -> Client.get("/redirect") end)
    assert log =~ "/redirect -> 301"
  end

  test "ok" do
    log = capture_log(fn -> Client.get("/ok") end)
    assert log =~ "/ok -> 200"
  end
end
