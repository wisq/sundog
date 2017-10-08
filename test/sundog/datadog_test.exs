defmodule Sundog.DatadogTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Sundog.Datadog

  setup_all do
    [:datadog_api_key, :datadog_application_key, :datadog_host]
    |> Enum.each(fn target ->
      source = :"vcr_#{target}"
      value = Application.get_env(:sundog, source, "not set")
      Application.put_env(:sundog, target, value)

      ExVCR.Config.filter_sensitive_data(
        Regex.escape(value), 
        source |> Atom.to_string |> String.upcase
      )
    end)
    :ok
  end

  test "query_series_latest_time/2 extracts last datapoint time from series" do
    latest = use_cassette "query_cpu_idle" do
      Datadog.query_series_latest_time("system.cpu.idle", 1234)
    end

    # Ensure that our concept of "now" changes
    # based on when this test was recorded.
    now = File.stat!("fixture/vcr_cassettes/query_cpu_idle.json",
                     time: :posix).ctime

    assert latest < now # can fail if NTP sync badly off
    assert_in_delta latest, now, 60.0 # within one minute
  end

  test "query_series_latest_time/2 handles no datapoints in window" do
    latest = use_cassette "query_nonexistent" do
      Datadog.query_series_latest_time("nonexistent", 1234)
    end

    assert latest == nil
  end

  test "submit_datapoints/2 submits datapoints to Datadog" do
    use_cassette "submit_sundog_test" do
      [time1, time2, time3] =
        [3, 2, 1]
        |> Enum.map(fn mins ->
          Timex.now
          |> Timex.subtract(Timex.Duration.from_minutes(mins))
          |> Timex.to_unix
        end)

      assert Datadog.submit_datapoints("sundog.test.1", [
        {time1, 10},
        {time2, 20},
        {time3, 30},
      ]) == :ok
    end
  end
end
