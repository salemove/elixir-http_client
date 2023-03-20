defmodule Salemove.HttpClient.Middleware.Proxy do
  @behaviour Tesla.Middleware

  @moduledoc """
  Adds proxy server options to a request if either of the following conditions are met:
  * Environment variable `http_proxy` (or `HTTP_PROXY`) is set and requested protocol is `http://`
  * Environment variable `https_proxy` (or `HTTPS_PROXY`) is set and requested protocol is `https://`

  Proxy options are not injected if either of the following conditions are met:
  * Requested host is included into `no_proxy` (or `NO_PROXY`) environment variable
  * Http client is configured with option `proxy: false`
  """

  def call(env, next, opts) do
    if Keyword.get(opts, :proxy, []) do
      env
      |> inject_proxy(opts)
      |> Tesla.run(next)
    else
      env
      |> inject_adapter(opts)
      |> Tesla.run(next)
    end
  end

  # The code below is copied from https://github.com/edgurgel/httpoison/blob/fa2238cfb9833776e5eebdb2d73d0e1a0093a356/lib/httpoison/base.ex#L818-L851

  defp inject_proxy(env, opts) do
    proxy =
      if Keyword.has_key?(opts, :proxy) do
        Keyword.get(opts, :proxy) |> check_no_proxy(env.url)
      else
        case URI.parse(env.url).scheme do
          "http" -> System.get_env("HTTP_PROXY") || System.get_env("http_proxy")
          "https" -> System.get_env("HTTPS_PROXY") || System.get_env("https_proxy")
          _ -> nil
        end
        |> check_no_proxy(env.url)
      end

    proxy_options =
      opts
      |> Keyword.take(~w[proxy_auth socks5_user socks5_pass]a)
      |> Keyword.put(:proxy, proxy)

    new_options =
      opts
      |> adapter_options()
      |> Keyword.update(:__adapter_options, proxy_options, fn adapter_options ->
        adapter_options ++ proxy_options
      end)

    %{env | opts: new_options}
  end

  defp adapter_options(opts) do
    [__adapter: opts[:adapter], __adapter_options: opts[:adapter_options]]
  end

  defp inject_adapter(env, opts) do
    %{env | opts: adapter_options(opts)}
  end

  defp check_no_proxy(nil, _) do
    # Don't bother to check no_proxy if there's no proxy to use anyway.
    nil
  end

  defp check_no_proxy(proxy, request_url) do
    request_host = URI.parse(request_url).host

    should_bypass_proxy =
      get_no_proxy_system_env()
      |> String.split(",")
      |> Enum.any?(fn domain -> matches_no_proxy_value?(request_host, String.trim(domain)) end)

    if should_bypass_proxy do
      nil
    else
      proxy
    end
  end

  defp get_no_proxy_system_env() do
    System.get_env("NO_PROXY") || System.get_env("no_proxy") || ""
  end

  defp matches_no_proxy_value?(request_host, no_proxy_value) do
    cond do
      no_proxy_value == "" ->
        false

      String.starts_with?(no_proxy_value, ".") ->
        String.ends_with?(request_host, no_proxy_value) || request_host == String.trim_leading(no_proxy_value, ".")

      String.contains?(no_proxy_value, "*") ->
        matches_wildcard?(request_host, no_proxy_value)

      true ->
        request_host == no_proxy_value
    end
  end

  defp matches_wildcard?(request_host, wildcard_domain) do
    Regex.escape(wildcard_domain)
    |> String.replace("\\*", ".*")
    |> Regex.compile!()
    |> Regex.match?(request_host)
  end
end
