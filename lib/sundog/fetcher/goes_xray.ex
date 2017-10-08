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
    [short_data, long_data] = split_data(data, 2)

    Submitter.submit_datapoints("sundog.goes.xray", short_data, state.tags ++ [source: source, wavelength: "short"])
    Submitter.submit_datapoints("sundog.goes.xray", long_data,  state.tags ++ [source: source, wavelength: "long"])

    {:ok, state}
  end

  def split_data(data, count) do
    (1..count)
    |> Enum.map(&extract_data(data, &1))
  end

  def extract_data(data, index) do
    data
    |> Enum.map(fn [time | _] = item ->
      {time, Enum.at(item, index)}
    end)
    |> Enum.reject(fn {_t, v} -> is_nil(v) end)
  end
end
