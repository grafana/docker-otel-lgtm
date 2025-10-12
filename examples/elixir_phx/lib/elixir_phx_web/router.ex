defmodule ElixirPhxWeb.Router do
  use ElixirPhxWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ElixirPhxWeb do
    pipe_through :api

    get "/", HealthController, :check

    # Dice roll endpoint for generating traces
    get "/rolldice", DiceController, :roll
    get "/rolldice/:sides", DiceController, :roll_with_sides
    post "/rolldice/:sides", DiceController, :roll_with_sides
  end
end
