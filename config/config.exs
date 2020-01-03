# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :secret_hitler,
  ecto_repos: [SecretHitler.Repo]

# Configures the endpoint
config :secret_hitler, SecretHitlerWeb.Endpoint,
  live_view: [signing_salt: System.get_env("SECRET_HITLER_SIGNING_SALT")],
  url: [host: "localhost"],
  secret_key_base: "VXyWJcxhkA07F2v8YUwFGbJBHs7UNu8CNjf8aeYQNGfO78eFY2icf5coZoN3SQ6W",
  render_errors: [view: SecretHitlerWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: SecretHitler.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :phoenix, template_engines: [leex: Phoenix.LiveView.Engine]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
