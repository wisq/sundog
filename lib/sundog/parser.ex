defmodule Sundog.Parser do
  def parse(text) do
    lines = text
            |> String.split("\n")
            |> Enum.group_by(&line_type/1)

    headers = parse_headers(lines[:header])
    data = parse_data(headers, lines[:data])

    {headers, data}
  end

  def line_type(line) do
    case String.first(line) do
      ":" -> :header
      "#" -> :header
      nil -> :empty
      _   -> :data
    end
  end

  defp parse_headers(headers) do
    headers
    |> Enum.map(&parse_header_line/1)
    |> Enum.filter(fn x -> !is_nil(x) end)
    |> Map.new
  end

  defp parse_header_line(line) do
    case Regex.run(~r/^[:#]\s([A-Za-z ]+): (.*)$/, line) do
      [_, key, value] -> {key, value}
      nil -> nil
    end
  end

  defp parse_data(%{"Missing data" => missing}, data) do
    data
    |> Enum.map(&(parse_data_line(&1, missing)))
  end

  defp parse_data_line(line, missing) do
    [year, month, day, time, _, _ | fields] = Regex.split(~r/\s+/, line)

    {hour, minute} = String.split_at(time, 2)
    [year, month, day, hour, minute] = 
      [year, month, day, hour, minute]
      |> Enum.map(&String.to_integer/1)

    time = Timex.to_datetime({{year, month, day}, {hour, minute, 0}}, :utc)
    data = fields |> Enum.map(&(parse_data_field(&1, missing)))

    [time | data]
  end

  defp parse_data_field(missing, missing), do: nil
  defp parse_data_field(field, _missing), do: String.to_float(field)
end
