defmodule Sundog.Fetcher.GoesXray do
  use Sundog.Fetcher
  alias Sundog.Submitter

  def fetcher_name(state) do
    primary = case state.tags[:primary] do
      true  -> "primary"
      false -> "secondary"
    end

    "#{super(state)}[#{primary}]"
  end

  def handle_fetched_data(headers, data, state) do
    source = headers |> Map.fetch!("Source")

    [short: 1, long: 2]
    |> Enum.map(&async_submit(&1, data, source, state))
    |> Enum.map(&Task.await/1)

    {:ok, state}
  end

  def extract_data(data, index) do
    data
    |> Enum.map(fn [time | _] = item ->
      {time, Enum.at(item, index)}
    end)
    |> Enum.reject(fn {_t, v} -> is_nil(v) end)
  end

  def async_submit({wavelength, index}, data, source, state) do
    Task.async(fn ->
      points = extract_data(data, index)
      count = Submitter.submit_datapoints(
        "sundog.goes.xray",
        points,
        state.tags ++ [source: source, wavelength: wavelength]
      )

      Logger.info("#{fetcher_name(state)}: Submitted #{count} #{wavelength}-wave stats.")
    end)
  end
end
