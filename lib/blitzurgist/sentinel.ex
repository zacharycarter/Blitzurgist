defmodule Blitzurgist.Sentinel do
  @moduledoc """
  The `Sentinel` module provides a behavior for a rate limiter.
  """

  @callback observe(observe_handler :: tuple(), observation_handler :: tuple()) :: :ok

  def observe(observe_handler, observation_handler) do
    get_sentinel().observe(observe_handler, observation_handler)
  end

  def get_sentinel, do: get_sentinel_config(:sentinel)
  def get_observations_per_timeframe, do: get_sentinel_config(:timeframe_max_observations)
  def get_timeframe_unit, do: get_sentinel_config(:timeframe_units)
  def get_timeframe, do: get_sentinel_config(:timeframe)

  def calculate_refresh_rate(num_observations, time, timeframe_units) do
    floor(convert_time_to_milliseconds(timeframe_units, time) / num_observations)
  end

  def convert_time_to_milliseconds(:hours, time), do: :timer.hours(time)
  def convert_time_to_milliseconds(:minutes, time), do: :timer.minutes(time)
  def convert_time_to_milliseconds(:seconds, time), do: :timer.seconds(time)
  def convert_time_to_milliseconds(:milliseconds, milliseconds), do: milliseconds

  defp get_sentinel_config(config) do
    :blitzurgist
    |> Application.get_env(Sentinel)
    |> Keyword.get(config)
  end
end
