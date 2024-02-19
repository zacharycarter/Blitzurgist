defmodule Blitzurgist.Spell do
  @moduledoc """
  The `Spell` module serves as a HTTP client for querying the Riot API.
  """
  require Logger

  alias Blitzurgist.Summoner
  alias Req.Response

  def cast(reagents, summoner_name \\ "") do
    case Req.get(reagents[:incantation], headers: headers(reagents), decode_json: [keys: :atoms]) do
      {:ok, %Response{body: %{name: _} = summoner_dto, status: 200}} ->
        Logger.debug(
          "A summoning spell has been cast to summon #{reagents[:summoner_name]} from the region of #{reagents[:region]}!"
        )

        {Summoner.new(summoner_dto), reagents}

      {:ok, %Response{body: matches, status: 200}} ->
        {matches, reagents, summoner_name}

      {:ok, %Response{body: %{status: %{message: msg}}}} ->
        {:failure, msg, reagents}

      {:error, err} ->
        {:error, err, reagents}
    end
  end

  defp headers(reagents),
    do: [
      {"Accept-Charset", "application/x-www-form-urlencoded; charset=UTF-8"},
      {"X-Riot-Token", reagents[:magic_word]}
    ]
end
