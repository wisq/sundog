defmodule Sundog.Datadog do
  use Memoize

  defp api_key do
    Application.get_env(:sundog, :datadog_api_key) ||
      System.get_env("DD_API_KEY") ||
      raise "Must set DD_API_KEY"
  end
  defp application_key do
    Application.get_env(:sundog, :datadog_application_key) ||
      System.get_env("DD_APPLICATION_KEY") ||
      raise "Must set DD_APPLICATION_KEY"
  end
  defp host do
    Application.get_env(:sundog, :datadog_host) || 
      System.get_env("DD_HOST") ||
      get_os_hostname()
  end

  defmemo get_os_hostname do
    {output, 0} = System.cmd("hostname", ["-f"])
    output |> String.trim
  end

  defp default_params do
    %{
      api_key: api_key(),
      application_key: application_key(),
      host: host(),
    }
  end

  def now do
    DateTime.utc_now
    |> DateTime.to_unix
  end

  def datadog_uri(path, params \\ []) do
    uri_params = Map.merge(default_params(), Map.new(params))
    %URI{
      scheme: "https",
      host: "app.datadoghq.com",
      path: Path.join("/api", path),
      query: URI.encode_query(uri_params),
    }
  end

  def query_last_datapoint_time(metric, seconds_ago \\ 3600) do
    datadog_uri(
      "v1/query",
      from: now() - seconds_ago,
      to: now(),
      query: "#{metric}{host:#{host()}}",
    )
    |> HTTPoison.get!
    |> Map.fetch!(:body)
    |> Poison.decode!
    |> Map.fetch!("series")
    |> List.first # first series returned
    |> Map.fetch!("pointlist")
    |> List.last  # last datapoint
    |> List.first # time
    |> round      # float to int
    |> div(1000)  # ms to s
  end

  @content_type_json ["Content-Type": "application/json"]

  def submit_datapoints(metric, points, tags \\ []) do
    body = datapoints_body(metric, points, tags) |> Poison.encode!

    datadog_uri("v1/series")
    |> HTTPoison.post!(body, @content_type_json)
  end

  defp datapoints_body(metric, points, tags) do
    %{
      series: [%{
        metric: metric,
        points: points |> encode_points,
        type: "gauge",
        host: host(),
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
