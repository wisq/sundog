defmodule Sundog.Submitter do
  alias Sundog.Submitter.{AgentSupervisor, Agent}

  def submit_datapoints(metric, points, tags \\ []) do
    AgentSupervisor.find_or_create_process(metric, tags)
    |> Agent.submit_datapoints(points)
  end 
end
