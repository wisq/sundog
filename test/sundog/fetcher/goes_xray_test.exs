defmodule Sundog.Fetcher.GoesXrayTest do
  use ExUnit.Case
  import Mock

  alias Sundog.Fetcher.GoesXray
  alias Sundog.Fetcher.State
  alias Sundog.Submitter
  alias Sundog.Parser

  @primary_url "http://services.swpc.noaa.gov/text/goes-xray-flux-primary.txt"

  test "handle_fetch_data/3 submits data to Datadog" do
    state = %State{url: @primary_url, tags: [primary: true]}
    {headers, data} = Parser.parse(File.read!(
      "test/data/noaa/goes-xray-flux-primary.txt"))

    me = self()
    with_mock Submitter, submit_datapoints: fn
      "sundog.goes.xray", _points, tags ->
        tags = tags |> Map.new
        assert tags.primary == true
        assert tags.source == "GOES-15"
        assert [:short, :long] |> Enum.member?(tags.wavelength)
        send(me, {:wavelength, tags.wavelength})
        :ok
    end do
      GoesXray.handle_fetched_data(headers, data, state)
    end

    assert_receive {:wavelength, :short}
    assert_receive {:wavelength, :long}
  end
end
