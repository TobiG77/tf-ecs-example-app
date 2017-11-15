defmodule HelloWorldApiWeb.Router do
  use HelloWorldApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", HelloWorldApiWeb do
    pipe_through :api
  end
end
