use Mix.Config

# You can put some real Datadog credentials here,
# and use them to re-record the ExVCR-based tests,
# AS LONG AS you don't mind that the tests will
#
#   * read some standard metrics for <host> (e.g. CPU)
#   * write ONE bogus metric for <host> (sundog.test)
#
# The tests do their best to censor these keys from
# the recorded VCR "cassettes", but remember to 
# carefully scrutinise any changes under "fixture/"
# to ensure that your credentials do not leak into
# the git commit history.
config :sundog,
  vcr_datadog_api_key: "api key",
  vcr_datadog_application_key: "application key",
  # Ensure this is a real, active host that is
  # currently producing data.  The tests expect
  # there to be data from within the last minute.
  vcr_datadog_host: "name of some existing host"
