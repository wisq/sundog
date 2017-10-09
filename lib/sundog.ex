defmodule Sundog do
  use Application
  require Logger

  @version Mix.Project.config[:version]
  def version, do: @version

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    children = if supervise?() do
      [
        Sundog.Submitter.Supervisor,
        Sundog.Fetcher.Supervisor,
      ]
    else
      []
    end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sundog.Supervisor]

    Logger.info("Sundog starting up ...")
    Supervisor.start_link(children, opts)
  end

  def supervise? do
    !iex_running?() && Application.get_env(:sundog, :supervise, true)
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?
  end
end
