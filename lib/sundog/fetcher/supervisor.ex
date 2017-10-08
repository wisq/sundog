defmodule Sundog.Fetcher.Supervisor do
  use Supervisor
  require Logger

  alias Sundog.Fetcher, as: Fetch

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    workers = [
      Supervisor.child_spec(
        {
          Fetch.GoesXray,
          url: "http://services.swpc.noaa.gov/text/goes-xray-flux-primary.txt",
          tags: [primary: true],
        },
        id: :goes_xray_primary
      ),

      Supervisor.child_spec(
        {
          Fetch.GoesXray,
          url: "http://services.swpc.noaa.gov/text/goes-xray-flux-secondary.txt",
          tags: [primary: false],
        },
        id: :goes_xray_secondary
      ),
    ]

    Supervisor.init(workers, strategy: :one_for_one)
  end
end
