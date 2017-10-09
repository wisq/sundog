defmodule Sundog.Fetcher.AceSwepamTest do
  use ExUnit.Case
  import Mock

  alias Sundog.Fetcher.AceSwepam
  alias Sundog.Fetcher.State
  alias Sundog.Submitter
  alias Sundog.Parser

  @primary_url "http://services.swpc.noaa.gov/text/ace-swepam.txt"

  test "handle_fetch_data/3 submits data to Datadog" do
    state = %State{url: @primary_url, tags: []}
    {headers, data} = Parser.parse(File.read!(
      "test/data/noaa/ace-swepam.txt"))

    me = self()
    with_mock Submitter, submit_datapoints: fn
      (metric, points, tags) ->
        send(me, {:submitted, metric, points, tags})
        :ok
    end do
      AceSwepam.handle_fetched_data(headers, data, state)
    end

    assert_receive {:submitted, "sundog.ace_swepam.proton_density", points, status: :nominal}
    assert Enum.count(points) == 113
    assert_receive {:submitted, "sundog.ace_swepam.proton_density", points, status: :bad_data}
    # There are six lines with :bad_data status,
    # but only three of them have non-missing values.
    assert Enum.count(points) == 3

    assert_receive {:submitted, "sundog.ace_swepam.bulk_speed", points, status: :nominal}
    assert Enum.count(points) == 113
    assert_receive {:submitted, "sundog.ace_swepam.bulk_speed", points, status: :bad_data}
    assert Enum.count(points) == 3

    assert_receive {:submitted, "sundog.ace_swepam.ion_temperature", points, status: :nominal}
    assert Enum.count(points) == 113
    assert_receive {:submitted, "sundog.ace_swepam.ion_temperature", points, status: :bad_data}
    assert Enum.count(points) == 3

    # End of submissions.
    refute_receive {:submitted, _, _, _}
  end
end
