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

  defp parse_missing(missing) do
    values =
      cond do
        missing |> String.contains?(", ") ->
          missing
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&parse_missing/1)

        missing |> String.contains?(" = ") ->
          missing
          |> String.split("=", parts: 2)
          |> List.last
          |> String.trim
          |> to_list

        true ->
          missing
          |> String.trim
          |> to_list
      end

    values |> List.flatten
  end

  defp to_list(list) when is_list(list), do: list
  defp to_list(value), do: [value]

  defp parse_data(%{"Missing data" => missing}, data) do
    missing_values = parse_missing(missing)
    data |> Enum.map(&(parse_data_line(&1, missing_values)))
  end

  defp parse_data(%{"Missing data values" => missing}, data) do
    missing_values = parse_missing(missing)
    data |> Enum.map(&(parse_data_line(&1, missing_values)))
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

  defp parse_data_field(field, missing) do
    if missing |> Enum.member?(field) do
      nil
    else
      to_number(field)
    end
  end

  defp to_number(str) do
    if str |> String.contains?(".") do
      str |> String.to_float
    else
      str |> String.to_integer
    end
  end
end
