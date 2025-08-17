# Use the official Elixir image with Erlang/OTP
FROM elixir:1.18-alpine AS build

# Install system dependencies
RUN apk add --no-cache \
    build-base \
    git \
    postgresql-client

# Set the working directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

FROM build AS dev

ENV MIX_ENV=dev

# Copy the mix files and install dependencies
COPY mix.exs mix.lock ./

COPY config/config.exs config/${MIX_ENV}.exs config/

RUN mix deps.get && mix deps.compile

# Copy the source code
COPY priv priv

COPY lib lib

# Compile the application
RUN mix compile

# Set environment
ENV PHX_SERVER=true

# Expose the port
EXPOSE 4000

# Start the Phoenix server
CMD ["mix", "phx.server"]
