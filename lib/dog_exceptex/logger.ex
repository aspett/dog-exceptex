defmodule DogExceptex.Logger do
  @moduledoc """
  Logging backend for Datadog. Funnels exceptions and error-level logging into
  datadog error events
  """
  @behaviour :gen_event

  alias DogExceptex.ExceptionFormatter

  defmodule State do
    defstruct [:statsd_pid, :statsd_host, :statsd_port, :event_opts, level: :error]
    use Accessible
  end

  def init(_) do
    config = Application.get_env(:logger, :dog_exceptex)

    {:ok, state} = configure(config, %State{})

    case get_or_start_statsd_pid(state) do
      {:ok, pid} ->
        {:ok, %State{state | statsd_pid: pid}}

      error ->
        error
    end
  end

  # Logger.configure_backend/2 will call this. Implementing this behaviour
  # allows runtime configuration changes.
  def handle_call({:configure, config}, state) do
    {:ok, state} = configure(config, state)
    {:ok, state, state}
  end

  def handle_call(_message, state) do
    {:ok, :ok, state}
  end

  def handle_event({_level, gleader, _event}, state) when node(gleader) != node() do
    {:ok, state}
  end

  def handle_event(
        {level, _, {Logger, msg, _ts, meta}},
        %State{statsd_pid: pid, event_opts: opts, level: configured_level} = state
      ) do
    if Logger.compare_levels(level, configured_level) != :lt do
      with %{title: title, body: body, key: key} <- ExceptionFormatter.format_error(msg, meta) do
        opts = Map.put_new(opts, :aggregation_key, key)
        DogStatsd.event(pid, title, body, opts)
      end
    end

    {:ok, state}
  end

  def handle_event(
        {level, _, {DogExceptex.Plug, _msg, _ts, %{title: title, body: body, key: key}}},
        %State{statsd_pid: pid, event_opts: opts, level: configured_level} = state
      ) do
    if Logger.compare_levels(level, configured_level) != :lt do
      opts = Map.put_new(opts, :aggregation_key, key)
      DogStatsd.event(pid, title, body, opts)
    end

    {:ok, state}
  end

  def handle_event(_log, state) do
    {:ok, state}
  end

  def handle_info(_info, state) do
    {:ok, state}
  end

  defp get_or_start_statsd_pid(%State{statsd_pid: pid, statsd_host: host, statsd_port: port}) do
    case pid do
      pid when is_pid(pid) -> {:ok, pid}
      _ -> DogStatsd.new(host, port)
    end
  end

  defp configure(config, state) do
    allowed_keys =
      %State{}
      |> Map.from_struct()
      |> Map.keys()

    new_state =
      (config || [])
      |> Enum.into(%{})
      |> Map.take(allowed_keys)

    new_state =
      state
      |> Map.merge(new_state)
      |> update_in([:event_opts], fn opts -> Enum.into(opts || %{}, %{}) end)
      |> update_in([:event_opts], fn opts -> Map.put_new(opts, :alert_type, "error") end)
      |> update_in([:event_opts, :tags], fn
        nil ->
          []

        tags ->
          Enum.map(tags, fn
            {k, v} -> "#{k}:#{v}"
            tag -> tag
          end)
      end)

    if is_nil(new_state.statsd_host) && is_nil(new_state.statsd_port) &&
         is_nil(new_state.statsd_pid) do
      {:error,
       "expected dog_except logger to be configured with statsd_host and statsd_port or statsd_pid"}
    else
      {:ok, new_state}
    end
  end
end
