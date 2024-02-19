defmodule Blitzurgist.Soothsayer do
  @moduledoc """
  The `Soothsayer` module supervises the `Seer` module which
  consumes from the `Conjurer` module.
  """

  use ConsumerSupervisor

  require Logger

  alias Blitzurgist.Seer

  def start_link(conjuring, conjurer) do
    Registry.start_link(keys: :unique, name: Seers)

    ConsumerSupervisor.start_link(__MODULE__, conjurer, name: divine(conjuring))
  end

  def init(conjurer) do
    Logger.debug(
      "A soothsayer is pulling back the curtains of time to see what the future holds for the summoning ritual and its practitioners!"
    )

    children = [
      %{
        id: Seer,
        start: {Seer, :start_link, []},
        restart: :transient
      }
    ]

    opts = [strategy: :one_for_one, subscribe_to: [{conjurer, max_demand: 10, min_demand: 1}]]
    ConsumerSupervisor.init(children, opts)
  end

  defp divine(conjuring) do
    {:via, Registry, {Seers, conjuring}}
  end
end
