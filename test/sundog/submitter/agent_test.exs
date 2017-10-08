defmodule Sundog.Submitter.AgentTest do
  use ExUnit.Case
  import Mock

  alias Sundog.Submitter.Agent
  alias Sundog.Datadog

  @agent_name :sundog_submitter_agent_test

  test "submit_datapoints/2 submits data to Datadog" do
    metric = "my.metric"
    points = sample_data(5)
    tags = [foo: "bar", baz: "qux"]

    {:ok, pid} = Agent.start_link(@agent_name, metric: metric, tags: tags)

    with_mock Datadog, [submit_datapoints: fn(^metric, ^points, ^tags) -> :ok end] do
      assert 5 = Agent.submit_datapoints(pid, points)
      assert called Datadog.submit_datapoints(metric, points, tags)
    end

    GenServer.stop(pid)
  end

  test "submit_datapoints/2 only submits data more recent than latest data seen" do
    metric = "second.metric"
    before_points  = sample_data(3, 21..30)
    overlap_points = sample_data(3, 11..20)
    after_points   = sample_data(3,  1..10)
    tags = []

    {:ok, pid} = Agent.start_link(@agent_name, metric: metric, tags: tags)

    points1 = before_points ++ overlap_points
    points2 = overlap_points ++ after_points

    with_mock Datadog, [submit_datapoints: fn(^metric, ^points1, ^tags) -> :ok end] do
      assert 6 = Agent.submit_datapoints(pid, points1)
      assert called Datadog.submit_datapoints(metric, points1, tags)
    end

    with_mock Datadog, [submit_datapoints: fn(^metric, ^after_points, ^tags) -> :ok end] do
      assert 3 = Agent.submit_datapoints(pid, points2)
      assert called Datadog.submit_datapoints(metric, after_points, tags)
    end

    GenServer.stop(pid)
  end

  test "submit_datapoints/2 submits nothing if repeatedly called with same points" do
    metric = "second.metric"
    points = sample_data(5)
    tags = []

    {:ok, pid} = Agent.start_link(@agent_name, metric: metric, tags: tags)

    with_mock Datadog, [submit_datapoints: fn(^metric, ^points, ^tags) -> :ok end] do
      assert 5 = Agent.submit_datapoints(pid, points)
      assert called Datadog.submit_datapoints(metric, points, tags)
    end

    with_mock Datadog, [submit_datapoints: fn(_, _, _) -> raise "don't call me" end] do
      assert 0 = Agent.submit_datapoints(pid, points)
      assert 0 = Agent.submit_datapoints(pid, points)
    end

    GenServer.stop(pid)
  end

  def sample_data(count, minutes_ago \\ 1..30) do
    minutes_ago
    |> Enum.take_random(count)
    |> Enum.map(fn mins ->
      Timex.now
      |> Timex.subtract(Timex.Duration.from_minutes(mins))
      |> Timex.to_unix
    end)
    |> Enum.sort
    |> Enum.map(fn unix_time ->
      {unix_time, Enum.random(1..1_000_000_000) / 1000.0} # 1 to 1 million w/ 3 decimals
    end)
  end
end
