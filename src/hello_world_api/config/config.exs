# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :hello_world_api,
  ecto_repos: [HelloWorldApi.Repo]

# Configures the endpoint
config :hello_world_api, HelloWorldApiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "f1B/9CJTCbj5mjRzDq463MDcOI59dlGgIn2PQGlwVB5RnJ7oRMH1Iu2ApkjPZQyO",
  render_errors: [view: HelloWorldApiWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: HelloWorldApi.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
