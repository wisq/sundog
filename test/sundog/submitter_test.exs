defmodule Sundog.SubmitterTest do
  use ExUnit.Case
  import Mock

  alias Sundog.Submitter
  alias Sundog.Datadog

  setup do
    start_supervised(Sundog.Submitter.Supervisor)
    :ok
  end

  test "submit_datapoints/3 submits data to Datadog" do
    metric1 = "my.metric"
    points1 = sample_data(5)
    tags1 = [foo: "bar", baz: "qux"]

    metric2 = "other.metric"
    points2 = sample_data(5)
    tags2 = [more: "tags"]

    with_mock Datadog, [submit_datapoints: fn
      (^metric1, ^points1, ^tags1) -> :ok
      (^metric2, ^points2, ^tags2) -> :ok
    end] do
      assert 5 = Submitter.submit_datapoints(metric1, points1, tags1)
      assert 5 = Submitter.submit_datapoints(metric2, points2, tags2)
      assert called Datadog.submit_datapoints(metric1, points1, tags1)
      assert called Datadog.submit_datapoints(metric2, points2, tags2)
    end
  end

  test "submit_datapoints/3 only submits data more recent than latest data seen (per metric & tags)" do
    metric1 = "metric.one"
    metric2 = "metric.two"
    before_points  = sample_data(3, 21..30)
    overlap_points = sample_data(3, 11..20)
    after_points   = sample_data(3,  1..10)
    tags = []

    points1a = before_points ++ overlap_points
    points2a = before_points

    points1b = points2b = overlap_points ++ after_points

    with_mock Datadog, [submit_datapoints: fn
      (^metric1, ^points1a, ^tags) -> :ok
      (^metric2, ^points2a, ^tags) -> :ok
    end] do
      assert 6 = Submitter.submit_datapoints(metric1, points1a, tags)
      assert 3 = Submitter.submit_datapoints(metric2, points2a, tags)
      assert called Datadog.submit_datapoints(metric1, points1a, tags)
      assert called Datadog.submit_datapoints(metric2, points2a, tags)
    end

    with_mock Datadog, [submit_datapoints: fn
      (^metric1, ^after_points, ^tags) -> :ok  # overlap omitted
      (^metric2, ^points2b, ^tags) -> :ok      # overlap included
    end] do
      assert 3 = Submitter.submit_datapoints(metric1, points1b, tags)
      assert 6 = Submitter.submit_datapoints(metric2, points2b, tags)
      assert called Datadog.submit_datapoints(metric1, after_points, tags)
      assert called Datadog.submit_datapoints(metric2, points2b, tags)
    end
  end

  test "submit_datapoints/3 submits nothing if repeatedly called with same metric + points + tags" do
    metric = "another.metric"
    points1 = sample_data(5)
    points2 = sample_data(5)
    tags1 = [type: 1]
    tags2 = [type: 2]

    with_mock Datadog, [submit_datapoints: fn
      (^metric, ^points1, ^tags1) -> :ok
      (^metric, ^points2, ^tags2) -> :ok
    end] do
      Submitter.submit_datapoints(metric, points1, tags1)
      Submitter.submit_datapoints(metric, points2, tags2)
      assert called Datadog.submit_datapoints(metric, points1, tags1)
      assert called Datadog.submit_datapoints(metric, points2, tags2)
    end

    with_mock Datadog, [submit_datapoints: fn(_, _, _) -> raise "don't call me" end] do
      Submitter.submit_datapoints(metric, points1, tags1)
      Submitter.submit_datapoints(metric, points2, tags2)
      Submitter.submit_datapoints(metric, points1, tags1)
      Submitter.submit_datapoints(metric, points2, tags2)
    end
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
