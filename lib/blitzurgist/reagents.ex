defmodule Blitzurgist.Reagents do
  @moduledoc """
  Configurable options for `Blitzurgist`.
  """

  @magic_word "Abracadabra"
  @match_api_base_url "api.riotgames.com/lol/match/v5/matches"
  @routes_by_region %{
    "br1" => "americas",
    "eun1" => "europe",
    "euw1" => "europe",
    "jp1" => "asia",
    "kr" => "asia",
    "la1" => "americas",
    "la2" => "americas",
    "na1" => "americas",
    "oc1" => "sea",
    "ph2" => "sea",
    "ru" => "europe",
    "sg2" => "sea",
    "th2" => "sea",
    "tr1" => "europe",
    "tw2" => "sea",
    "vn2" => "sea"
  }
  @spell_caster Blitzurgist.Spell
  @summoner_api_base_url "api.riotgames.com/lol/summoner/v4/summoners"
  @summoner_puuid_length 78

  def defaults(reagents) do
    :persistent_term.put({__MODULE__, :match_api_base_url}, match_api_base_url())
    :persistent_term.put({__MODULE__, :summoner_api_base_url}, summoner_api_base_url())

    Map.merge(
      %{
        magic_word: magic_word(),
        spell_caster: spell_caster()
      },
      reagents
    )
  end

  def incantation(reagents, summoner_name, region) do
    Map.merge(reagents, %{
      summoner_name: summoner_name,
      region: region,
      incantation:
        URI.encode(
          "https://#{region}.#{:persistent_term.get({__MODULE__, :summoner_api_base_url})}/by-name/#{summoner_name}"
        )
    })
  end

  def incantation(reagents, summoner)
      when byte_size(summoner) == @summoner_puuid_length do
    Map.merge(reagents, %{
      incantation:
        URI.encode(
          "https://#{reagents[:route]}.#{:persistent_term.get({__MODULE__, :match_api_base_url})}/by-puuid/#{summoner}/ids?start=0&count=5"
        )
    })
  end

  def incantation(reagents, match_id) do
    Map.merge(reagents, %{
      incantation:
        URI.encode(
          "https://#{reagents[:route]}.#{:persistent_term.get({__MODULE__, :match_api_base_url})}/#{match_id}"
        )
    })
  end

  def incantation(reagents, summoner, start_time, end_time)
      when byte_size(summoner) == @summoner_puuid_length do
    Map.merge(reagents, %{
      incantation:
        URI.encode(
          "https://#{reagents[:route]}.#{:persistent_term.get({__MODULE__, :match_api_base_url})}/by-puuid/#{summoner}/ids?startTime=#{start_time}&endTime=#{end_time}&start=0&count=20"
        )
    })
  end

  def invoker(reagents, invoker) do
    Map.merge(reagents, %{
      invoker: invoker
    })
  end

  def region(reagents, region) when is_map_key(@routes_by_region, region) do
    Map.merge(reagents, %{region: region, route: @routes_by_region[region]})
  end

  def region(_reagents, region) do
    raise RuntimeError, message: "invalid region: #{region}"
  end

  defp magic_word, do: Application.get_env(:blitzurgist, :magic_word, @magic_word)

  defp match_api_base_url,
    do: Application.get_env(:blitzurgist, :match_api_base_url, @match_api_base_url)

  defp summoner_api_base_url,
    do: Application.get_env(:blitzurgist, :summoner_api_base_url, @summoner_api_base_url)

  defp spell_caster,
    do: Application.get_env(:blitzurgist, :spell_caster, @spell_caster)
end
