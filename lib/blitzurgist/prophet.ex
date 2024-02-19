defmodule Blitzurgist.Prophet do
  @moduledoc """
  The `Prophet` module supervises the `Chronicler` module which
  consumes from the `Conjurer` module.
  """

  use ConsumerSupervisor

  require Logger

  alias Blitzurgist.Chronicler

  def start_link(prophecy, seer) do
    Registry.start_link(keys: :unique, name: Almanac)

    ConsumerSupervisor.start_link(__MODULE__, seer, name: observe(prophecy))
  end

  def init(seer) do
    Logger.debug("The prophet has begun to analyze a prophecy!")

    children = [
      %{
        id: Chronicler,
        start: {Chronicler, :start_link, []},
        restart: :transient
      }
    ]

    opts = [strategy: :one_for_one, subscribe_to: [{seer, max_demand: 10, min_demand: 1}]]
    ConsumerSupervisor.init(children, opts)
  end

  defp observe(prophecy) do
    {:via, Registry, {Almanac, prophecy}}
  end
end
