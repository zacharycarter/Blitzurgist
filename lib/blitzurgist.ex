defmodule Blitzurgist do
  @moduledoc """
  The `Blitzurgist` module sets up the application's supervision hierarchy
  and provides the `summon/3` function to initiate the GenStage pipeline.
  """

  use Application

  alias Blitzurgist.Archmage
  alias Blitzurgist.Compendium
  alias Blitzurgist.Invoker
  alias Blitzurgist.Reagents
  alias Blitzurgist.Sentinel

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Blitzurgist.TaskSupervisor},
      {Sentinel.get_sentinel(),
       %{
         timeframe_max_observations: Sentinel.get_observations_per_timeframe(),
         timeframe_units: Sentinel.get_timeframe_unit(),
         timeframe: Sentinel.get_timeframe()
       }},
      Compendium,
      Invoker,
      Archmage
    ]

    opts = [strategy: :one_for_one, name: Blitzurgist.Supervisor]

    Supervisor.start_link(children, opts)
  end

  @doc """
  Fetches all summoners that the summoner, matching the provided `summoner_name` argument, has played with in the last five matches.

  Returns a list of summoner names in the format: ["summoner_name_one", "summoner_name_two", ...].

  ## Examples

      iex> Blitzurgist.summon("foo", "us")
      ["summoner_name_one", "summoner_name_two"]

  """
  @spec summon(String.t(), String.t()) ::
          list(String.t()) | {:error, :invalid_region | :invalid_summoner_name}
  def summon(summoner_name, region, reagents \\ [])

  def summon(summoner_name, region, reagents)
      when is_binary(summoner_name) and is_binary(region) do
    with region <- trim_and_downcase(region),
         summoner_name <- trim_and_downcase(summoner_name) do
      reagents =
        reagents
        |> Enum.into(%{})
        |> Reagents.defaults()
        |> Reagents.region(region)
        |> Reagents.incantation(summoner_name, region)

      Invoker.invoke(reagents)
    end
  end

  def summon(nil, _, _), do: {:error, :invalid_summoner_name}
  def summon(_, nil, _), do: {:error, :invalid_region}
  @spec summon() :: {:error, [:invalid_region | :invalid_summoner_name, ...]}
  def summon(), do: {:error, [:invalid_summoner_name, :invalid_region]}

  defp trim_and_downcase(string) do
    string
    |> String.trim()
    |> String.downcase()
  end
end
