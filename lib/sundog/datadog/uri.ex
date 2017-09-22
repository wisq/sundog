defmodule Sundog.Datadog.URI do
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
  def host do
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
end
