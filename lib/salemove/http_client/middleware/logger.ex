defmodule Salemove.HttpClient.Middleware.Logger do
  @behaviour Tesla.Middleware

  @moduledoc """
  Log requests as single line.

  Logs request method, url, response status and time taken in milliseconds.

  ### Example usage
  ```
  defmodule MyClient do
    use Tesla

    plug Salemove.HttpClient.Middleware.Logger,
      level: %{
        100..399 => :info,
        422 => :info,
        400..499 => :warn,
        500..600 => :error
      }
  end
  ```

  ### Logger output
  ```
  2017-09-30 13:39:06.663 [info] GET http://example.com -> 200 (736.988 ms)
  ```
  """

  require Logger

  def call(env, next, opts) do
    time_start = System.monotonic_time()

    with {:ok, env} <- Tesla.run(env, next) do
      elapsed_ms = elapsed_ms(time_start)

      log(env, elapsed_ms, metadata(env, elapsed_ms), opts)
      {:ok, env}
    else
      {:error, error} ->
        elapsed_ms = elapsed_ms(time_start)

        log(env, error, elapsed_ms, metadata(env, elapsed_ms), opts)
        {:error, error}
    end
  end

  defp log(env, :timeout, elapsed_ms, metadata, _opts) do
    message = "#{normalize_method(env)} #{env.url} -> :timeout (#{elapsed_ms} ms)"
    Logger.log(:warn, message, metadata ++ [status: "timeout"])
  end

  defp log(env, :closed, elapsed_ms, metadata, _opts) do
    message = "#{normalize_method(env)} #{env.url} -> :closed (#{elapsed_ms} ms)"
    Logger.log(:warn, message, metadata ++ [status: "closed"])
  end

  defp log(env, %Tesla.Error{reason: reason}, elapsed_ms, metadata, opts) do
    status = inspect(reason)

    log_status(
      0,
      "#{normalize_method(env)} #{env.url} -> #{status} (#{elapsed_ms} ms)",
      metadata ++ [status: normalize_status(status)],
      opts
    )
  end

  defp log(env, error, elapsed_ms, metadata, opts) do
    status = inspect(error)

    log_status(
      0,
      "#{normalize_method(env)} #{env.url} -> #{status} (#{elapsed_ms} ms)",
      metadata ++ [status: normalize_status(status)],
      opts
    )
  end

  defp log(env, elapsed_ms, metadata, opts) do
    message = "#{normalize_method(env)} #{env.url} -> #{env.status} (#{elapsed_ms} ms)"

    log_status(env.status, message, metadata ++ [status: normalize_status(env.status)], opts)
  end

  defp normalize_method(env) do
    env.method |> to_string() |> String.upcase()
  end

  defp normalize_status(status), do: to_string(status)

  defp elapsed_ms(from) do
    now = System.monotonic_time()
    us = System.convert_time_unit(now - from, :native, :microsecond)
    :io_lib.format("~.3f", [us / 1000])
  end

  defp log_status(status, message, metadata, opts) do
    levels = Keyword.get(opts || [], :level)

    status
    |> status_to_level(levels)
    |> Logger.log(message, metadata)
  end

  defp status_to_level(status, levels) when is_map(levels) do
    case levels do
      %{^status => level} -> level
      levels -> find_matching_level(levels, status) || status_to_level(status, nil)
    end
  end

  defp status_to_level(status, _) do
    cond do
      status >= 500 -> :warn
      status >= 400 || status == 0 -> :error
      status >= 300 -> :warn
      true -> :info
    end
  end

  defp find_matching_level(levels, status) do
    Enum.find_value(levels, fn
      {%Range{} = range, level} -> if status in range, do: level
      {^status, level} -> level
      _ -> false
    end)
  end

  defp metadata(env, elapsed_ms) do
    [method: normalize_method(env), path: env.url, duration_ms: to_string(elapsed_ms)]
  end
end
