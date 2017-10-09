defmodule Sundog.Submitter.AgentSupervisor do
  use Supervisor
  require Logger

  alias Sundog.Submitter.Agent

  @registry_name Sundog.Submitter.Registry
  def registry_name, do: @registry_name

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    agent_spec = Supervisor.child_spec(
      Agent,
      start: {Agent, :start_link, []},
      restart: :temporary, # on-demand only
    )
    Supervisor.init([agent_spec], strategy: :simple_one_for_one)
  end

  def find_or_create_process(metric, tags) do
    id = process_id(metric, tags)

    case lookup_process(id) do
      {:ok, {pid, nil}} -> pid
      {:not_found} -> create_process(id, metric: metric, tags: tags)
    end
  end

  defp process_id(metric, tags) when is_binary(metric) do
    {metric, tags |> Map.new}
  end

  defp lookup_process(id) do
    case Registry.lookup(@registry_name, id) do
      [] -> {:not_found}
      [pid] -> {:ok, pid}
    end
  end

  defp create_process(id, opts) do
    case start_agent(id, opts) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  defp start_agent(id, opts) do
    name = {:via, Registry, {@registry_name, id}}
    Supervisor.start_child(__MODULE__, [name, opts])
  end
end
