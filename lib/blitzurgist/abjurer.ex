defmodule Blitzurgist.Abjurer do
  @moduledoc """
  The `Abjurer` module consumes from the `Chronicler` and is
  responsible for polling the Riot matches API for each summoner
  retrieved during the GenStage pipeline.

  When a summoner plays a new match, a message is logged to the console.
  """
  use GenStage

  require Logger

  alias Blitzurgist.Reagents
  alias Blitzurgist.Scribe
  alias Blitzurgist.Sentinel

  @abjurer __MODULE__

  def start_link({{portal, _}, _}, summoning) do
    Registry.start_link(keys: :unique, name: Portals)

    GenStage.start_link(@abjurer, summoning, name: seal(portal))
  end

  def init(summoning) do
    {:consumer, 0, subscribe_to: [{summoning, max_demand: 50}]}
  end

  def handle_events(summonings, _summoning, observations) do
    Enum.each(summonings, fn {{summoner_name, summoner}, reagents} ->
      Logger.debug(
        "An abjurer has sealed the portal #{summoner_name} emerged from! They will continue observing this summoner..."
      )

      observe(summoner_name, summoner, reagents)
    end)

    {:noreply, [], observations}
  end

  def handle_info({:gaze, {summoner_name, summoner, reagents, start_time}}, observations) do
    Logger.debug("The summoner who goes by the name #{summoner_name} is being gazed upon!")

    if observations < 60 do
      Sentinel.observe(
        {@abjurer, :start_observation, [reagents, summoner, start_time, summoner_name]},
        {@abjurer, :finish_observation}
      )

      observe(summoner_name, summoner, reagents)
      {:noreply, [], observations + 1}
    else
      {:stop, :normal, observations}
    end
  end

  def start_observation(reagents, summoner, start_time, summoner_name) do
    reagents
    |> Reagents.incantation(summoner, start_time, System.system_time(:second))
    |> reagents[:spell_caster].cast(summoner_name)
    |> Scribe.transcribe(false)
  end

  def finish_observation({appearances, _reagents, summoner_name}) do
    Enum.each(appearances, fn appearance ->
      Logger.info("Summoner #{summoner_name} completed match #{appearance}")
    end)
  end

  defp observe(summoner_name, summoner, reagents) do
    Process.send_after(
      self(),
      {:gaze, {summoner_name, summoner, reagents, System.system_time(:second)}},
      60 * 1000
    )
  end

  defp seal(portal) do
    {:via, Registry, {Portals, portal}}
  end
end
