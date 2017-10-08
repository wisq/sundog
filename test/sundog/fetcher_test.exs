defmodule Sundog.FetcherTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Sundog.Fetcher

  @url "http://services.swpc.noaa.gov/text/goes-xray-flux-primary.txt"

  defmodule StaticUrlFetcher do
    use Fetcher, url: "http://services.swpc.noaa.gov/text/goes-xray-flux-primary.txt"

    def handle_fetched_data(headers, data, state) do
      send(state.tags[:static_pid], {:handled, headers, data, state})
      {:ok, state}
    end
  end

  defmodule DynamicUrlFetcher do
    use Fetcher

    def handle_fetched_data(headers, data, state) do
      send(state.tags[:dynamic_pid], {:handled, headers, data, state})
      {:ok, state}
    end
  end

  test "can start static URL fetcher and perform run" do
    {:ok, pid} = start_supervised({
      StaticUrlFetcher,
      tags: [static_pid: self()],
    })

    use_cassette "fetcher_goes_primary" do
      send(pid, :run)

      assert_receive {:handled, headers, data, state}, 5000
      assert state.url == @url
      assert headers["Source"] |> String.starts_with?("GOES-")
      assert_in_delta 120, Enum.count(data), 5
    end

    stop_supervised(pid)
  end

  test "can start dynamic URL fetcher and perform run" do
    {:ok, pid} = start_supervised({
      DynamicUrlFetcher,
      url: @url,
      tags: [dynamic_pid: self()],
    })

    use_cassette "fetcher_goes_secondary" do
      send(pid, :run)

      assert_receive {:handled, headers, data, state}, 5000
      assert state.url == @url
      assert headers["Source"] |> String.starts_with?("GOES-")
      assert_in_delta 120, Enum.count(data), 5
    end

    stop_supervised(pid)
  end
end
