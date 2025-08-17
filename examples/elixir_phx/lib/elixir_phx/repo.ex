defmodule ElixirPhx.Repo do
  use Ecto.Repo,
    otp_app: :elixir_phx,
    adapter: Ecto.Adapters.Postgres
end
