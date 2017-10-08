defmodule Sundog.Datadog do
  use Memoize

  alias Sundog.Datadog.URI, as: DDURI

  defp now do
    DateTime.utc_now
    |> DateTime.to_unix
  end

  def query_series_latest_time(metric, seconds_ago \\ 3600) do
    DDURI.datadog_uri(
      "v1/query",
      from: now() - seconds_ago,
      to: now(),
      query: "#{metric}{host:#{DDURI.host()}}",
    )
    |> HTTPoison.get!
    |> Map.fetch!(:body)
    |> Poison.decode!
    |> series_latest_time
  end

  def series_latest_time(%{"series" => [%{"pointlist" => points}]}) do
    [time, _value] = points |> List.last

    time
    |> round      # float to int
    |> div(1000)  # ms to s
  end

  def series_latest_time(%{"series" => [%{"pointlist" => []}]}), do: nil
  def series_latest_time(%{"series" => []}), do: nil

  @content_type_json ["Content-Type": "application/json"]

  def submit_datapoints(metric, points, tags \\ []) do
    body = datapoints_body(metric, points, tags) |> Poison.encode!

    %HTTPoison.Response{status_code: 202} =
      DDURI.datadog_uri("v1/series")
      |> HTTPoison.post!(body, @content_type_json)

    :ok
  end

  defp datapoints_body(metric, points, tags) do
    %{
      series: [%{
        metric: metric,
        points: points |> encode_points,
        type: "gauge",
        host: DDURI.host(),
        tags: tags |> encode_tags,
      }]
    }
  end

  defp encode_points(points) do
    points
    |> Enum.map(fn {t, v} -> [to_unix_time(t), v] end)
  end

  defp to_unix_time(%DateTime{} = t), do: t |> DateTime.to_unix
  defp to_unix_time(t) when is_integer(t), do: t

  defp encode_tags(tags) do
    tags
    |> Enum.map(fn {k, v} -> "#{k}:#{v}" end)
    |> Enum.join(",")
  end
end
