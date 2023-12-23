defmodule ExBanking.RateLimiter do
  @moduledoc """
  This module implements a rate-limiting mechanism using the sliding window technique.

  The sliding window technique allows you to restrict the number of events or requests
  that can occur within a specified time window, helping to prevent abuse,
  manage system load, and ensure fair usage.

  ## Config
  ```
  config :ex_banking, :rate_limit,
    # Size of the rate limiting window in milliseconds.
    window_size_ms: 60 * 1000,
    # The maximum number of requests allowed for the window.
    maximum_request_count: 10,
    # Interval in the milliseconds for removing outdated data from the usage table.
    cleanup_interval_ms: 120 * 1000
  ```
  """
  use GenServer

  @window_size Application.compile_env(:ex_banking, [:rate_limit, :window_size_ms])
  @max_request_count Application.compile_env(:ex_banking, [:rate_limit, :maximum_request_count])
  @cleanup_interval Application.compile_env(:ex_banking, [:rate_limit, :cleanup_interval_ms])

  require Record

  Record.defrecordp(
    # A unique name of the record.
    :usage,
    # Record key, a tuple of `{api_key :: String.t(), window_start_timestamp :: integer()}`.
    key: nil,
    # Usage count for the window — i.e. the number of requests made since the window started.
    usage: 0,
    # Usage count that isn't yet synced to other nodes in a cluster.
    pending_usage: 0
  )

  @doc """
  Starts the RateLimiter GenServer process linked to the current process.
  """
  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec track(String.t()) :: :ok | {:error, :limit_reached}
  def track(api_key) do
    # Calculate the start of the current window.
    current_timestamp = now()
    current_window_start = window_start(current_timestamp, @window_size)
    # And use it in the record key.
    record_key = {api_key, current_window_start}

    [current_window_usage, _current_window_pending_usage] =
      update_window_usage(record_key)

    # Calculate the start of the previous window.
    previous_window_start = current_window_start - @window_size

    # Query the table for the previous window usage record.
    previous_window_usage = get_window_usage(api_key, previous_window_start)

    IO.inspect({current_window_usage, previous_window_usage}, label: "currentm prev usage")

    # Calculate how much of the current window already elapsed.
    window_elapsed_ratio = (current_timestamp - current_window_start) / @window_size

    # Then calculate the usage with the sliding window algorithm formula.
    usage = current_window_usage + (1 - window_elapsed_ratio) * previous_window_usage

    IO.inspect({usage, @max_request_count}, label: "usage")

    if usage > @max_request_count do
      # We already incremented the usage counters. We need to fix
      # the usage record since the request will be rate limited.
      update_window_usage(record_key, _increment_counter = -1)
      {:error, :limit_reached}
    else
      # Request should be allowed.
      :ok
    end
  end

  @impl true
  def init(_init_args) do
    # Create ETS table
    create_table()

    # Schedule outdated data cleanup. Scheduled regularly at data cleanup interval.
    Process.send_after(self(), :perform_cleanup, @cleanup_interval)

    {:ok, %{}}
  end

  @impl true
  def handle_info(:perform_cleanup, state) do
    IO.puts("Performing ets table cleanup")
    # Clean up records with windows that are older than the previous window.
    previous_window_start = window_start(now(), @window_size) - @window_size

    # Atomically query and delete usage records that are older than the previous window.
    :ets.select_delete(
      table_name(),
      # :ets.fun2ms(fn {:usage, {_, timestamp}, _, _}
      #   when timestamp < previous_window_start -> true end)
      [
        {
          {:usage, {:_, :"$1"}, :_, :_},
          [{:<, :"$1", previous_window_start}],
          [true]
        }
      ]
    )

    # Schedule the next cleanup cycle.
    Process.send_after(self(), :perform_cleanup, @cleanup_interval)

    {:noreply, state}
  end

  # To keep things simple, we'll use the module name as the name of our ETS table.
  defp table_name(), do: __MODULE__

  defp create_table do
    :ets.new(
      table_name(),
      [
        # Our table is a set of values, i.e. each key in the table needs to be unique.
        :set,
        # We'll access this table from processes that handle our requests.
        # Setting it to ``:public`` makes it accessible from any process.
        :public,
        # Named tables can be accessed using their name.
        :named_table,
        # Inform the ETS about the index of our record keys.
        # Note that this ETS property is indexed from `1`: Erlang uses
        # `1`-based indexes for tuples, while Elixir tuples are `0`-based.
        keypos: usage(:key) + 1
      ]
    )
  end

  defp window_start(timestamp, window_size) do
    timestamp - rem(timestamp, window_size)
  end

  defp now do
    System.system_time(:millisecond)
  end

  defp get_window_usage(api_key, window_start) do
    case :ets.lookup(table_name(), {api_key, window_start}) do
      [] ->
        # No window usage record.
        0

      [usage(usage: window_usage)] ->
        window_usage
    end
  end

  defp update_window_usage(record_key, increment_counter \\ 1) do
    :ets.update_counter(
      table_name(),
      record_key,
      # Increment the `usage` and `pending_usage` values.
      # The syntax here expects the position in the record (again `1`-based).
      [{usage(:usage) + 1, increment_counter}, {usage(:pending_usage) + 1, increment_counter}],
      # We need to provide the default item in case there's
      # not yet a record for the current window.
      usage(key: record_key, usage: 0, pending_usage: 0)
    )
  end
end
