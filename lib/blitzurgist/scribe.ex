defmodule Blitzurgist.Scribe do
  @moduledoc """
  The `Scribe` module handles responses from the Riot API.
  """
  require Logger

  alias Blitzurgist.Summoner

  def transcribe({%Summoner{puuid: summoner}, reagents}) do
    Logger.debug("A scribe is furiously transcribing the results of the summoning spell!")
    {summoner, reagents}
  end

  def transcribe({:failure, msg, reagents}) do
    Logger.error(
      "A scribe is recording that the summoning spelled has fizzled for the following reason: #{msg}!"
    )

    GenStage.reply(reagents[:invoker], [])

    nil
  end

  def transcribe({:error, err, reagents}) do
    Logger.error(
      "The summoning spell has gone catastrophically wrong! The summoner has reported a: #{inspect(err)}"
    )

    GenStage.reply(reagents[:invoker], [])

    nil
  end

  def transcribe(
        {%{info: %{participants: participants}},
         %{summoner_name: original_summoner_name} = reagents, summoner_name}
      ) do
    {
      participants
      |> greet_participants()
      |> select_participants(original_summoner_name)
      |> join_participants_with_summoning_chain(),
      reagents,
      summoner_name
    }
  end

  def transcribe({[_ | _] = match_ids, reagents, summoner_name}, true) do
    Logger.debug("The scribe slowly nods their head as the summoning chain strengthens!")
    {match_ids, reagents, summoner_name}
  end

  def transcribe({[] = match_ids, reagents, summoner_name}, true) do
    Logger.debug(
      "The scribe double-checks their work as the summoning chain appears to be weakening!"
    )

    {match_ids, reagents, summoner_name}
  end

  def transcribe({match_ids, reagents, summoner_name}, false) do
    {match_ids, reagents, summoner_name}
  end

  defp greet_participants(participants) do
    Enum.map(participants, fn participant ->
      %{
        summoner_name: String.downcase(String.trim(participant[:summonerName])),
        summoner: participant[:puuid]
      }
    end)
  end

  defp select_participants(participants, original_summoner_name) do
    Enum.filter(participants, fn participant ->
      participant.summoner_name != nil and participant.summoner_name != original_summoner_name
    end)
  end

  defp join_participants_with_summoning_chain(participants) do
    Enum.map(participants, fn %{summoner_name: summoner_name, summoner: summoner} ->
      Logger.debug(
        "#{summoner_name} has emerged from a portal and has joined in the summoning chain!"
      )

      {String.replace(String.downcase(String.trim(summoner_name)), " ", "_"), summoner}
    end)
  end
end
