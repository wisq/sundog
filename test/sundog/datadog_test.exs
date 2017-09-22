defmodule Sundog.DatadogTest do
  use ExUnit.Case
  alias Sundog.Datadog
  import Mock

  def random_string(count \\ 20) do
    upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    lower = String.downcase(upper)
    numbers = "0123456789"
    characters = upper <> lower <> numbers |> String.to_charlist

    (1..count)
    |> Enum.map(fn _ -> Enum.random(characters) end)
    |> Enum.join
  end

  test "datadog_uri/2 generates correct URIs from config" do
    Application.put_env(:sundog, :datadog_api_key, api_key = random_string())
    Application.put_env(:sundog, :datadog_application_key, app_key = random_string())
    Application.put_env(:sundog, :datadog_host, host = random_string())

    assert %URI{
      host: "app.datadoghq.com",
      path: "/api/path1",
      query: query,
    } = Datadog.datadog_uri(
      "path1",
      key1: value1 = random_string(),
      key2: value2 = random_string()
    )

    q = URI.decode_query(query)
    assert q["api_key"] == api_key
    assert q["application_key"] == app_key
    assert q["host"] == host
    assert q["key1"] == value1
    assert q["key2"] == value2
  end

  test "datadog_uri/2 generates correct URIs from environment" do
    Application.delete_env(:sundog, :datadog_api_key)
    Application.delete_env(:sundog, :datadog_application_key)
    Application.delete_env(:sundog, :datadog_host)

    System.put_env("DD_API_KEY", api_key = random_string())
    System.put_env("DD_APPLICATION_KEY", app_key = random_string())
    System.put_env("DD_HOST", host = random_string())

    assert %URI{
      host: "app.datadoghq.com",
      path: "/api/v2/path2",
      query: query,
    } = Datadog.datadog_uri(
      "/v2/path2",
      key3: value3 = random_string(),
      key4: value4 = random_string()
    )

    q = URI.decode_query(query)
    assert q["api_key"] == api_key
    assert q["application_key"] == app_key
    assert q["host"] == host
    assert q["key3"] == value3
    assert q["key4"] == value4
  end

  test "datadog_uri/2 falls back to get_os_hostname/0" do
    Application.put_env(:sundog, :datadog_api_key, "dummy")
    Application.put_env(:sundog, :datadog_application_key, "dummy")
    Application.delete_env(:sundog, :datadog_host)
    System.delete_env("DD_HOST")

    assert %URI{query: query} = Datadog.datadog_uri("/path3")

    q = URI.decode_query(query)
    assert q["host"] == Datadog.get_os_hostname
  end

  test "get_os_hostname/0 is memoized" do
    host1 = Datadog.get_os_hostname
    with_mock System, [cmd: fn(_, _) -> raise "System.cmd called" end] do
      assert Datadog.get_os_hostname == host1
    end
  end
end
