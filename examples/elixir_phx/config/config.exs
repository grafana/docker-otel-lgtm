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
  traces_exporter: :otlp,
  span_processor: :batch

# config :opentelemetry, traces_exporter: {:otel_exporter_stdout, []}

# config :opentelemetry, :processors,
#   otel_batch_processor: %{
#     exporter: {:opentelemetry_exporter, %{endpoints: [{:http, "lgtm", 4318, []}]}}
#   }

# Configure the OpenTelemetry HTTP exporter to send to local collector
config :opentelemetry_exporter,
  otlp_protocol: :http_protobuf,
  otlp_endpoint: "http://0.0.0.0:4318"

# otlp_headers: [],
# otlp_compression: :gzip

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
