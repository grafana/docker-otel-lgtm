defmodule ElixirPhxWeb.Router do
  use ElixirPhxWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ElixirPhxWeb do
    pipe_through :api

    # Health check endpoint
    get "/health", HealthController, :check

    # Dice roll endpoint for generating traces
    get "/dice", DiceController, :roll
    post "/dice/:sides", DiceController, :roll_with_sides
  end
end
