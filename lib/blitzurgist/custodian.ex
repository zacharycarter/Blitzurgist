defmodule Blitzurgist.Custodian do
  @moduledoc """
  The `Custodian` module implements the `Sentinel` behavior and serves
  as a token-based rate limiter.
  """

  use GenServer

  require Logger

  alias Blitzurgist.Sentinel

  @behaviour Sentinel

  @custodian __MODULE__

  def start_link(opts) do
    GenServer.start_link(@custodian, opts, name: @custodian)
  end

  @impl true
  def init(opts) do
    state = %{
      observations_per_timeframe: opts.timeframe_max_observations,
      available_observations: opts.timeframe_max_observations,
      observation_refresh_rate:
        Sentinel.calculate_refresh_rate(
          opts.timeframe_max_observations,
          opts.timeframe,
          opts.timeframe_units
        ),
      observation_queue: :queue.new(),
      observation_queue_size: 0,
      observe_after_ref: nil
    }

    {:ok, state, {:continue, :initial_timer}}
  end

  @impl Sentinel
  def observe(observe_handler, observation_handler) do
    GenServer.cast(@custodian, {:enqueue_observation, observe_handler, observation_handler})
  end

  @impl true
  def handle_continue(:initial_timer, state) do
    {:noreply, %{state | observe_after_ref: schedule_timer(state.observation_refresh_rate)}}
  end

  @impl true
  def handle_cast(
        {:enqueue_observation, observe_handler, observation_handler},
        %{available_observations: 0} = state
      ) do
    updated_queue = :queue.in({observe_handler, observation_handler}, state.observation_queue)
    new_queue_size = state.observation_queue_size + 1

    {:noreply,
     %{state | observation_queue: updated_queue, observation_queue_size: new_queue_size}}
  end

  def handle_cast({:enqueue_observation, observe_handler, observation_handler}, state) do
    async_task_request(observe_handler, observation_handler)

    {:noreply, %{state | available_observations: state.available_observations - 1}}
  end

  @impl true
  def handle_info(:observation_refresh, %{observation_queue_size: 0} = state) do
    token_count =
      if state.available_observations < state.observations_per_timeframe do
        state.available_observations + 1
      else
        state.available_observations
      end

    {:noreply,
     %{
       state
       | observe_after_ref: schedule_timer(state.observation_refresh_rate),
         available_observations: token_count
     }}
  end

  def handle_info(:observation_refresh, state) do
    {{:value, {observe_handler, observation_handler}}, new_request_queue} =
      :queue.out(state.observation_queue)

    async_task_request(observe_handler, observation_handler)

    {:noreply,
     %{
       state
       | observation_queue: new_request_queue,
         observe_after_ref: schedule_timer(state.observation_refresh_rate),
         observation_queue_size: state.observation_queue_size - 1
     }}
  end

  def handle_info({ref, _result}, state) do
    Process.demonitor(ref, [:flush])

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:noreply, state}
  end

  defp async_task_request(observe_handler, observation_handler) do
    start_message = "Observation started at #{NaiveDateTime.utc_now()}"

    Task.Supervisor.async_nolink(Blitzurgist.TaskSupervisor, fn ->
      {observe_module, observe_function, observe_commands} = observe_handler
      {observation_module, observation_function} = observation_handler

      response = apply(observe_module, observe_function, observe_commands)
      apply(observation_module, observation_function, [response])

      Logger.debug("#{start_message}\nObservation completed at #{NaiveDateTime.utc_now()}")
    end)
  end

  defp schedule_timer(observation_refresh_rate) do
    Process.send_after(self(), :observation_refresh, observation_refresh_rate)
  end
end
