defmodule Blitzurgist.Archmage do
  @moduledoc """
  The `Archmage` module supervises the `Summoner` module which
  consumes from the `Invoker` module.
  """
  use ConsumerSupervisor

  require Logger

  alias Blitzurgist.Invoker
  alias Blitzurgist.Summoner

  def start_link(_) do
    ConsumerSupervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    Logger.debug("An archmage has materialized in the center of the summoning circle!")

    children = [
      %{
        id: Summoner,
        start: {Summoner, :start_link, []},
        restart: :transient
      }
    ]

    opts = [strategy: :one_for_one, subscribe_to: [{Invoker, []}]]

    ConsumerSupervisor.init(children, opts)
  end
end
