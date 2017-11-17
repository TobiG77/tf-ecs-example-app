use Mix.Config

config :hello_world_api, HelloWorldApi.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "${POSTGRES_USERNAME}",
  password: "${POSTGRES_PASSWORD}",
  database: "${POSTGRES_DATABASE}",
  hostname: "${POSTGRES_HOSTNAME}",
  pool_size: 10
