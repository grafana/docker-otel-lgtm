#!/bin/bash

# Exit on any error
set -euo pipefail

echo "Starting Elixir Phoenix OpenTelemetry example..."

# Set environment variables for local development
export OTEL_SERVICE_NAME="elixir-phx-dice-server"
export OTEL_SERVICE_VERSION="0.1.0"
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318/v1/traces"
export PHX_SERVER=true
export MIX_ENV=dev

# Check if Docker is running
#Open Docker, only if is not running
if (! docker stats --no-stream &>/dev/null ); then
  # On Mac OS this would be the terminal command to launch Docker
  open /Applications/Docker.app
 #Wait until Docker daemon is running and has completed initialisation
while (! docker stats --no-stream &>/dev/null ); do
  # Docker takes a few seconds to initialize
  echo "Waiting for Docker to launch..."
  sleep 1
done
fi


echo "Starting PostgreSQL database using Docker..."
docker compose up db --remove-orphans -d

# Get dependencies and compile
echo "Setting up the Elixir Phoenix application..."
mix setup


echo "Starting Phoenix server with OpenTelemetry..."
echo "Server will be available at: http://localhost:4000"
echo "Dice roll: http://localhost:4000/rolldice"
echo "Custom dice: http://localhost:4000/api/dice/20"
echo ""
echo "Make sure the LGTM stack is running (run '../docker/run-all.sh' from the docker directory)"
echo ""

# Start the Phoenix server
iex -S mix phx.server