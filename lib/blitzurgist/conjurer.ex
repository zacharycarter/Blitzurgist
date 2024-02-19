defmodule Blitzurgist.Conjurer do
  @moduledoc """
  The `Conjurer` is supervised by the `Spellbinder` module and consumes messages
  from the `Summoner` module. It is responsible for querying the Riot matches
  API to retrieve a list of matches the summoner has played in recently.
  """

  use GenStage

  require Logger

  alias Blitzurgist.Compendium
  alias Blitzurgist.Reagents
  alias Blitzurgist.Scribe
  alias Blitzurgist.Soothsayer

  def start_link(conjuring) do
    GenStage.start_link(__MODULE__, conjuring)
  end

  def init(conjuring) do
    send(self(), {:conjure, conjuring})
    {:producer, {:queue.new(), 0}}
  end

  def handle_demand(demanded_conjurings, {grimoire, pending_conjurings}) do
    {conjurings, chain} = evoke(grimoire, demanded_conjurings + pending_conjurings, [])
    {:noreply, conjurings, chain}
  end

  def handle_info({:conjure, {summoner, reagents}}, {grimoire, pending_conjurings}) do
    Logger.debug(
      "A summoning spell has been bound to the chain with the aid of a conjurer, and another portal has opened!"
    )

    {conjurings, reagents, _summoner_name} =
      reagents
      |> Reagents.incantation(summoner)
      |> reagents[:spell_caster].cast()
      |> Scribe.transcribe(true)

    conjurings
    |> length()
    |> Compendium.mark_volumes()

    grimoire =
      Enum.reduce(conjurings, grimoire, fn conjuring, link ->
        :queue.in({conjuring, reagents}, link)
      end)

    {links, chain} = evoke(grimoire, pending_conjurings, [])

    Soothsayer.start_link({conjurings, reagents}, self())

    {:noreply, links, chain}
  end

  def handle_info({:conjure, nil}, {{[], []}, _}) do
    Logger.debug(
      "The spellbinder vanishes as quickly as they appeared as the summoning ritual has failed!"
    )

    {:stop, :normal, []}
  end

  defp evoke(grimoire, 0, conjurings) do
    {Enum.reverse(conjurings), {grimoire, 0}}
  end

  defp evoke(grimoire, demanded_conjurings, conjurings) do
    case :queue.out(grimoire) do
      {{:value, conjuring}, grimoire} ->
        evoke(grimoire, demanded_conjurings - 1, [conjuring | conjurings])

      {:empty, grimoire} ->
        {Enum.reverse(conjurings), {grimoire, demanded_conjurings}}
    end
  end
end
