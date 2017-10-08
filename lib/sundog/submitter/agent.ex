defmodule Sundog.Submitter.Agent do
  use GenServer
  alias Sundog.Datadog

  # Datadog doesn't allow you to backfill stats older than 1 hour.
  # We'll use 55 minutes to be safe.
  @datadog_backfill_minutes 55

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
    GenServer.cast(pid, {:submit, points})
  end

  def start_link(name, opts) do
    initial_state = %State{
      metric: opts[:metric],
      tags: opts[:tags],
      latest_time: 0,
    }
    GenServer.start_link(__MODULE__, initial_state, name: name)
  end

  def handle_cast({:submit, points}, %State{} = state) do
    IO.inspect(state)
    cutoff = [state.latest_time, datadog_cutoff_time()]
             |> Enum.max

    points = points
             |> Enum.map(&point_to_unix_time/1)
             |> Enum.filter(&point_more_recent_than(&1, cutoff))

    state = state |> datadog_submit(points)

    {:noreply, state}
  end

  defp datadog_cutoff_time do
    Timex.now
    |> Timex.subtract(Timex.Duration.from_minutes(@datadog_backfill_minutes))
    |> Timex.to_unix
  end

  defp point_to_unix_time({time, value}) do
    {time |> DateTime.to_unix, value}
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
