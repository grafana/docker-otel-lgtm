defmodule ElixirPhxWeb.HealthController do
  use ElixirPhxWeb, :controller

  def check(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{status: "ok", service: "elixir_phx", timestamp: DateTime.utc_now()})
  end
end
