defmodule ElixirPhxWeb.Router do
  use ElixirPhxWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ElixirPhxWeb do
    pipe_through :api
  end
end
