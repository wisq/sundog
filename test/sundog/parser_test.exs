defmodule Sundog.ParserTest do
  use ExUnit.Case
  alias Sundog.Parser

  test "parse/1 parses GOES text data" do
    {headers, data} = Parser.parse(File.read!(
      "test/data/noaa/goes-xray-flux-primary.txt"))

    assert headers["Source"] == "GOES-15"
    assert headers["Location"] == "W135"
    assert headers["Missing data"] == "-1.00e+05"

    assert Enum.count(data) == 120
    {:ok, stamp0} = DateTime.from_unix(1504686600)
    {:ok, stamp4} = DateTime.from_unix(1504686840)
    assert Enum.at(data, 0) == [stamp0, 1.36e-07, 1.99e-06]
    assert Enum.at(data, 4) == [stamp4, nil, nil]
  end
end
