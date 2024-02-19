defmodule Blitzurgist.Seer do
  @moduledoc """
  The `Seer` is supervised by the `Soothsayer` module and consumes messages
  from the `Conjurer` module. It is responsible for querying the Riot matches
  API to retrieve additional information about the matches which were retrieved
  by the `Conjurer`.
  """

  use GenStage

  require Logger

  alias Blitzurgist.Compendium
  alias Blitzurgist.Prophet
  alias Blitzurgist.Reagents
  alias Blitzurgist.Scribe

  def start_link(prophecy) do
    GenStage.start_link(__MODULE__, prophecy)
  end

  def init(prophecy) do
    send(self(), {:prophesize, prophecy})
    {:producer, {:queue.new(), 0}}
  end

  def handle_demand(demanded_prophecies, {grimoire, pending_prophecies}) do
    {prophecies, prognostication} = forsee(grimoire, demanded_prophecies + pending_prophecies, [])
    {:noreply, prophecies, prognostication}
  end

  def handle_info({:prophesize, {prophecy, reagents}}, {grimoire, pending_prophecies}) do
    Logger.debug("A prognostication is being delivered by a seer to the Prophet!")

    {prognostications, reagents, _summoner_name} =
      reagents
      |> Reagents.incantation(prophecy)
      |> reagents[:spell_caster].cast()
      |> Scribe.transcribe()
      |> encode_prognostication()

    grimoire =
      Enum.reduce(prognostications, grimoire, fn prognostication, epiphany ->
        :queue.in({prognostication, reagents}, epiphany)
      end)

    {prophecies, revelation} = forsee(grimoire, pending_prophecies, [])

    Prophet.start_link({prognostications, reagents}, self())

    {:noreply, prophecies, revelation}
  end

  defp encode_prognostication({prognostications, reagents, summoner_name}) do
    Compendium.encode(Enum.map(prognostications, &elem(&1, 0)))

    if Compendium.volumes() == Compendium.available_volumes(),
      do: GenStage.reply(reagents[:invoker], Compendium.archives())

    {prognostications, reagents, summoner_name}
  end

  defp forsee(grimoire, 0, prophecies) do
    {Enum.reverse(prophecies), {grimoire, 0}}
  end

  defp forsee(grimoire, demanded_prophecies, prophecies) do
    case :queue.out(grimoire) do
      {{:value, prophecy}, grimoire} ->
        forsee(grimoire, demanded_prophecies - 1, [prophecy | prophecies])

      {:empty, grimoire} ->
        {Enum.reverse(prophecies), {grimoire, demanded_prophecies}}
    end
  end
end
