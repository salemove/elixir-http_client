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
      _ = log(env, elapsed_ms(time_start), opts)

      {:ok, env}
    else
      {:error, %Tesla.Error{} = ex} ->
        _ = log(env, ex, elapsed_ms(time_start), opts)
        {:error, ex}

      {:error, error} ->
        {:error, error}
    end
  end

  defp log(env, %Tesla.Error{reason: reason}, elapsed_ms, opts) do
    log_status(0, "#{normalize_method(env)} #{env.url} -> #{inspect(reason)} (#{elapsed_ms} ms)", opts)
  end

  defp log(env, elapsed_ms, opts) do
    message = "#{normalize_method(env)} #{env.url} -> #{env.status} (#{elapsed_ms} ms)"

    log_status(env.status, message, opts)
  end

  defp normalize_method(env) do
    env.method |> to_string() |> String.upcase()
  end

  defp elapsed_ms(from) do
    now = System.monotonic_time()
    us = System.convert_time_unit(now - from, :native, :microsecond)
    :io_lib.format("~.3f", [us / 1000])
  end

  defp log_status(status, message, opts) do
    levels = Keyword.get(opts || [], :level)

    status
    |> status_to_level(levels)
    |> Logger.log(message)
  end

  defp status_to_level(status, levels) when is_map(levels) do
    case levels do
      %{^status => level} -> level
      levels -> find_matching_level(levels, status) || status_to_level(status, nil)
    end
  end

  defp status_to_level(status, _) do
    cond do
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
end
