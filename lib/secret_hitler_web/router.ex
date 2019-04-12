defmodule SecretHitlerWeb.Router do
  use SecretHitlerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SecretHitlerWeb do
    pipe_through :browser

    get "/:game_name", PageController, :index
    get "/", PageController, :index
  end
end
