defmodule BeaconSample.Repo do
  use Ecto.Repo,
    otp_app: :beacon_sample,
    adapter: Ecto.Adapters.Postgres
end
