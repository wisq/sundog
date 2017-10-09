defmodule Sundog.Submitter.Agent do
  use GenServer
  require Logger

  alias Sundog.Datadog

  defmodule State do
    @enforce_keys [:metric, :tags, :latest_time]
    defstruct(
      metric: nil,
      tags: nil,
      latest_time: nil,
    )
    @type t :: %State{metric: String.t, tags: Map.t, latest_time: non_neg_integer}
  end

  def submit_datapoints(pid, points) do
    GenServer.call(pid, {:submit, points})
  end

  def start_link(name, opts) do
    state = %State{
      metric: opts[:metric],
      tags: opts[:tags],
      latest_time: 0,
    }

    Logger.info "Starting Datadog submitter for #{inspect(state.metric)} with tags #{inspect(state.tags)}."
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def handle_call({:submit, points}, _from, %State{} = state) do
    points = points
             |> Enum.map(&point_to_unix_time/1)
             |> Enum.filter(&point_more_recent_than(&1, state.latest_time))

    state = state |> datadog_submit(points)

    {:reply, Enum.count(points), state}
  end

  defp point_to_unix_time({%DateTime{} = time, value}) do
    {time |> DateTime.to_unix, value}
  end
  defp point_to_unix_time({time, value}) when is_integer(time) do
    {time, value}
  end

  defp point_more_recent_than({time, _value}, cutoff) do
    time > cutoff
  end

  defp datadog_submit(state, []) do
    state
  end
  defp datadog_submit(state, points) do
    Datadog.submit_datapoints(state.metric, points, state.tags)

    %State{state | latest_time: latest_datapoint_time(points)}
  end

  defp latest_datapoint_time(points) do
    points
    |> Enum.map(fn {time, _value} -> time end)
    |> Enum.max
  end
end
