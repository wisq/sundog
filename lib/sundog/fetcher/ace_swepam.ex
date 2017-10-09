defmodule Sundog.Fetcher.AceSwepam do
  use Sundog.Fetcher
  alias Sundog.Submitter

  def handle_fetched_data(_headers, data, state) do
    [proton_density: 2, bulk_speed: 3, ion_temperature: 4]
    |> Enum.map(&submit_each_status(&1, data, state))
    |> List.flatten
    |> Enum.map(&Task.await/1)

    {:ok, state}
  end

  def extract_data(data, index) do
    data
    |> Enum.map(fn [time, status | _] = item ->
      {status_key(status), time, Enum.at(item, index)}
    end)
    |> Enum.reject(fn {_s, _t, v} -> is_nil(v) end)
  end

  def submit_each_status({metric, index}, data, state) do
    data
    |> extract_data(index)
    |> Enum.group_by(
      fn {status, _time, _value} -> status end,
      fn {_status, time, value} -> {time, value} end
    )
    |> Enum.map(&async_submit(&1, metric, state))
  end

  def async_submit({status, points}, metric, state) do
    Task.async(fn ->
      count = Submitter.submit_datapoints(
        "sundog.ace_swepam.#{metric}",
        points,
        state.tags ++ [status: status]
      )

      Logger.info("#{fetcher_name(state)}: Submitted #{count} #{metric} stats with status = #{inspect(status)}.")
    end)
  end

  def status_key(0), do: :nominal
  def status_key(9), do: :no_data
  def status_key(n) when n in 1..8, do: :bad_data
end
