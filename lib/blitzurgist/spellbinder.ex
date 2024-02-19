defmodule Blitzurgist.Spellbinder do
  @moduledoc """
  The `Spellbinder` module supervises the `Conjurer` module which
  consumes from the `Summoner` module.
  """

  use ConsumerSupervisor

  require Logger

  alias Blitzurgist.Conjurer

  def start_link(summoning, summoner) do
    Registry.start_link(keys: :unique, name: Summoners)

    ConsumerSupervisor.start_link(__MODULE__, summoner, name: bind(summoning))
  end

  def init(summoner) do
    Logger.debug("A spellbinder has emerged to establish a summoning chain!")

    children = [
      %{
        id: Conjurer,
        start: {Conjurer, :start_link, []},
        restart: :transient
      }
    ]

    opts = [strategy: :one_for_one, subscribe_to: [{summoner, max_demand: 10, min_demand: 1}]]
    ConsumerSupervisor.init(children, opts)
  end

  defp bind(summoning) do
    {:via, Registry, {Summoners, summoning}}
  end
end
