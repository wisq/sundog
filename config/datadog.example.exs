use Mix.Config

# To configure Sundog to log to your Datadog account,
# you can copy this file to config/datadog.exs and fill
# in your real Datadog credentials.
#
# Alternatively, you can supply your credentials via
# environment variables.  See the `README.md` for details.

config :sundog,
  datadog_api_key: "api key",
  datadog_application_key: "application key",
  # You'll want to ensure this is a real host
  # that is currently logging to datadog.
  datadog_host: "name of some existing host"
