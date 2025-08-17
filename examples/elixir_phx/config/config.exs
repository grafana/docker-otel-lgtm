# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :elixir_phx,
  ecto_repos: [ElixirPhx.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :elixir_phx, ElixirPhxWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ElixirPhxWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ElixirPhx.PubSub,
  live_view: [signing_salt: "W6tskPdn"]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# OpenTelemetry configuration
config :opentelemetry,
  span_processor: :batch,
  traces_exporter: :otlp,
  resource: [
    service: [
      name: "elixir_phx",
      version: "0.1.0"
    ]
  ]

# config :opentelemetry, :processors,
#   otel_batch_processor: %{
#     exporter: :otel_exporter_http
#   }

# Configure the OpenTelemetry HTTP exporter to send to local collector
config :opentelemetry_exporter,
  otlp_protocol: :http_protobuf,
  otlp_endpoint: System.get_env("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4318/v1/traces"),
  otlp_headers: [],
  otlp_compression: :gzip

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
