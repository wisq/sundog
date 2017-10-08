defmodule Sundog.Parser do
  def parse(text) do
    lines = text
            |> String.split("\n")
            |> Enum.group_by(&line_type/1)

    headers = parse_headers(lines[:header])
    data = parse_data(headers |> Map.new, lines[:data])

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
    |> Enum.reject(&is_nil/1)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Map.new(&nested_header/1)
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

  defp nested_header({key, value}) do
    {key, value |> nested_header_value}
  end

  defp nested_header_value([header]) do
    if String.contains?(header, "=") do
      [split_on_equals(header)]
      |> Map.new
    else
      header
    end
  end

  defp nested_header_value(headers) do
    headers
    |> Enum.map(&split_on_equals/1)
    |> Map.new
  end

  defp split_on_equals(str) do
    [key, value] =
      str
      |> String.split("=", parts: 2)
      |> Enum.map(&String.trim/1)

    {key, value}
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
