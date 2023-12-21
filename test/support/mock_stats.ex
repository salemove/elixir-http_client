defmodule MockStats do
  @behaviour Tesla.StatsD.Backend

  @impl true
  def gauge(_, _, _), do: :ok

  @impl true
  def histogram(_, _, _), do: :ok
end
