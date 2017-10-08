defmodule Sundog.Submitter.Supervisor do
  use Supervisor
  require Logger

  alias Sundog.Submitter.AgentSupervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    workers = [
      {Registry, keys: :unique, name: AgentSupervisor.registry_name},
      {AgentSupervisor, []},
    ]

    Supervisor.init(workers, strategy: :rest_for_one)
  end
end
