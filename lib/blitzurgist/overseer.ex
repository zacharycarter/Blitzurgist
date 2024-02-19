defmodule Blitzurgist.Overseer do
  @moduledoc """
  The `Overseer` module implements the `Sentinel` behavior and serves
  as a leaky bucket rate limiter.
  """

  use GenServer

  require Logger

  alias Blitzurgist.Sentinel

  @behaviour Sentinel

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    state = %{
      observation_queue: :queue.new(),
      observation_queue_size: 0,
      observation_queue_poll_rate:
        Sentinel.calculate_refresh_rate(
          opts.timeframe_max_observations,
          opts.timeframe,
          opts.timeframe_units
        ),
      observe_after_ref: nil
    }

    {:ok, state, {:continue, :initial_timer}}
  end

  @impl Sentinel
  def observe(observe_handler, observation_handler) do
    GenServer.cast(__MODULE__, {:enqueue_observation, observe_handler, observation_handler})
  end

  # ---------------- Server Callbacks ----------------

  @impl true
  def handle_continue(:initial_timer, state) do
    {:noreply, %{state | observe_after_ref: schedule_timer(state.observation_queue_poll_rate)}}
  end

  @impl true
  def handle_cast({:enqueue_observation, observe_handler, observation_handler}, state) do
    updated_queue = :queue.in({observe_handler, observation_handler}, state.observation_queue)
    new_queue_size = state.observation_queue_size + 1

    {:noreply,
     %{state | observation_queue: updated_queue, observation_queue_size: new_queue_size}}
  end

  @impl true
  def handle_info(:pop_from_observation_queue, %{observation_queue_size: 0} = state) do
    # No work to do as the queue size is zero...schedule the next timer
    {:noreply, %{state | observe_after_ref: schedule_timer(state.observation_queue_poll_rate)}}
  end

  def handle_info(:pop_from_observation_queue, state) do
    {{:value, {observe_handler, observation_handler}}, new_observation_queue} =
      :queue.out(state.observation_queue)

    start_message = "Observation started #{NaiveDateTime.utc_now()}"

    Task.Supervisor.async_nolink(Blitzurgist.TaskSupervisor, fn ->
      {req_module, req_function, req_args} = observe_handler
      {resp_module, resp_function} = observation_handler

      observation = apply(req_module, req_function, req_args)
      apply(resp_module, resp_function, [observation])

      Logger.debug("#{start_message}\nObservation completed #{NaiveDateTime.utc_now()}")
    end)

    {:noreply,
     %{
       state
       | observation_queue: new_observation_queue,
         observe_after_ref: schedule_timer(state.observation_queue_poll_rate),
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

  defp schedule_timer(queue_poll_rate) do
    Process.send_after(self(), :pop_from_observation_queue, queue_poll_rate)
  end
end
