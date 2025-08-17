#!/bin/bash

# Exit on any error
set -e

echo "Starting Elixir Phoenix OpenTelemetry example..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Get dependencies and compile
echo "Installing dependencies..."
mix deps.get
mix compile

# Set environment variables for local development
export OTEL_SERVICE_NAME="elixir-phx-dice-server"
export OTEL_SERVICE_VERSION="0.1.0"
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318/v1/traces"
export PHX_SERVER=true
export MIX_ENV=dev

echo "Starting Phoenix server with OpenTelemetry..."
echo "Server will be available at: http://localhost:4000"
echo "Health check: http://localhost:4000/api/health"
echo "Dice roll: http://localhost:4000/api/dice"
echo "Custom dice: http://localhost:4000/api/dice/20"
echo ""
echo "Make sure the LGTM stack is running (run '../docker/run-all.sh' from the docker directory)"
echo ""

# Start the Phoenix server
mix phx.server
