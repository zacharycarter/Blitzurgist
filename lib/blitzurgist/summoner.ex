defmodule Blitzurgist.Summoner do
  @moduledoc """
  The `Summoner` is supervised by the `Archmage` module and consumes messages
  from the `Invoker` module. It is responsible for querying the Riot summoners
  API to retrieve information about the summoner passed as an argument to the
  `Invoker`.
  """

  use GenStage

  require Logger

  alias Blitzurgist.Scribe
  alias Blitzurgist.Spellbinder

  @summoner __MODULE__

  defstruct accountId: "",
            profileIconId: -1,
            revisionDate: -1,
            name: "",
            id: "",
            puuid: "",
            summonerLevel: -1

  def new(fields) do
    struct!(@summoner, fields)
  end

  def start_link(ritual) do
    GenStage.start_link(@summoner, ritual)
  end

  def init(ritual) do
    Logger.debug("The archmage has beckoned a summoner to the summoning circle!")
    send(self(), {:summon, ritual})
    {:producer, {:queue.new(), 0}}
  end

  def handle_demand(demanded_rituals, {grimoire, pending_rituals}) do
    {summonings, rituals} = incant(grimoire, demanded_rituals + pending_rituals, [])
    {:noreply, summonings, rituals}
  end

  def handle_info({:summon, reagents}, {grimoire, pending_rituals}) do
    Logger.debug("The summoning ritual has begun!")

    summoning =
      reagents
      |> reagents[:spell_caster].cast()
      |> Scribe.transcribe()

    grimoire = :queue.in(summoning, grimoire)

    {summonings, rituals} = incant(grimoire, pending_rituals, [])

    Spellbinder.start_link(reagents, self())

    {:noreply, summonings, rituals}
  end

  defp incant(grimoire, 0, rituals) do
    {Enum.reverse(rituals), {grimoire, 0}}
  end

  defp incant(grimoire, demanded_rituals, rituals) do
    case :queue.out(grimoire) do
      {{:value, ritual}, grimoire} ->
        incant(grimoire, demanded_rituals - 1, [ritual | rituals])

      {:empty, grimoire} ->
        {Enum.reverse(rituals), {grimoire, demanded_rituals}}
    end
  end
end
