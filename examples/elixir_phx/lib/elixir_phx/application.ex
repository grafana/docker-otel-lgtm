defmodule ElixirPhx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require OpentelemetryPhoenix
  require OpentelemetryEcto

  @impl true
  def start(_type, _args) do
    setup_opentelemetry()

    children = [
      ElixirPhxWeb.Telemetry,
      ElixirPhx.Repo,
      {DNSCluster, query: Application.get_env(:elixir_phx, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ElixirPhx.PubSub},
      # Start a worker by calling: ElixirPhx.Worker.start_link(arg)
      # {ElixirPhx.Worker, arg},
      # Start to serve requests, typically the last entry
      ElixirPhxWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirPhx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp setup_opentelemetry do
    OpentelemetryBandit.setup()
    OpentelemetryPhoenix.setup(adapter: :bandit)
    # OpentelemetryEcto.setup([:elixir_phx, :repo])
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElixirPhxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
