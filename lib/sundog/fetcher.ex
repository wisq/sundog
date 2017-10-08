defmodule Sundog.Fetcher do
  defmodule State do
    @enforce_keys [:url]
    defstruct(
      url: nil,
      tags: [],
      run_timer: nil,
    )
    @type t :: %State{url: String.t, tags: Map.t}
  end

  defmacro __using__(opts) do
    quote location: :keep do
      use GenServer
      require Logger

      @opts unquote(opts)

      @default_interval 120 # 2 minutes
      @default_skew 15 # +/- 15 seconds
      @default_name "#{__MODULE__}" |> String.replace_leading("Elixir.Sundog.", "")

      def start_link(opts) do
        GenServer.start_link(__MODULE__, opts)
      end

      def init(opts) do
        {:ok, state} = fetcher_init(opts)
        {:ok, state |> queue_next_run}
      end

      def handle_info(:run, state) do
        cancel_run(state)

        {headers, data} =
          state.url
          |> Sundog.Fetcher.fetch!
          |> Sundog.Parser.parse

        {:ok, state} = handle_fetched_data(headers, data, state)

        {:noreply, state |> queue_next_run}
      end

      def fetcher_name(_state), do: fetcher_name()
      def fetcher_name, do: @default_name

      def fetcher_init(opts) do
        {:ok, struct!(State, @opts ++ opts)}
      end

      def handle_fetched_data(_, _, _) do
        raise "#{__MODULE__} must implement handle_fetched_data"
      end

      defoverridable [
        fetcher_name: 0,
        fetcher_name: 1,
        fetcher_init: 1,
        handle_fetched_data: 3,
      ]

      defp queue_next_run(state) do
        cancel_run(state)
        timer = run_after(state,
          @opts[:interval] || @default_interval,
          @opts[:skew] || @default_skew
        )
        state |> Map.replace!(:run_timer, timer)
      end

      defp run_after(state, interval, skew) do
        sleep = (-skew..skew)
                |> Enum.random
                |> Kernel.+(interval)
        
        Logger.info("#{fetcher_name(state)}: Next run in #{sleep} seconds.")
        Process.send_after(self(), :run, sleep * 1000)
      end

      defp cancel_run(%{run_timer: nil}), do: nil
      defp cancel_run(%{run_timer: timer}) when is_reference(timer) do
        Process.cancel_timer(timer)
      end
    end
  end

  def fetch!(url) do
    case HTTPoison.get!(url) do
      %{status_code: 200, body: body} -> body
      %{status_code: code} -> raise "Got HTTP code #{code} retrieving #{url}"
    end
  end
end
