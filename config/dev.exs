use Mix.Config

if File.exists?("config/datadog.exs") do
  import_config "datadog.exs"
end
