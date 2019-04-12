defmodule SecretHitler.Repo do
  use Ecto.Repo,
    otp_app: :secret_hitler,
    adapter: Ecto.Adapters.Postgres
end
