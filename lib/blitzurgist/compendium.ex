defmodule Blitzurgist.Compendium do
  @moduledoc """
  The `Compendium` module is responsible for storing interprocess state.
  Specifically it keeps track of the number of matches retrieved by the
  `Conjurer` module, the summoner names which are retrieved by the `Seer`
  module and finally the number of times the API has been polled when
  checking for matches for each summoner that has participated in a
  recent match.
  """
  use Agent

  @compendium __MODULE__

  def start_link(_) do
    Agent.start_link(fn -> {0, 0, []} end, name: @compendium)
  end

  def archives do
    Agent.get(@compendium, fn {_, _, records} ->
      records
      |> Enum.frequencies()
      |> Map.keys()
    end)
  end

  def volumes do
    Agent.get(@compendium, fn {_, incantations, _} -> incantations end)
  end

  def available_volumes do
    Agent.get(@compendium, fn {available_volumes, _, _} -> available_volumes end)
  end

  def mark_volumes(available) do
    Agent.update(@compendium, fn {_, incantations, prognostications} ->
      {available, incantations, prognostications}
    end)
  end

  def encode(prognostications) do
    Agent.update(@compendium, fn {available_volumes, incantations, records} ->
      {available_volumes, incantations + 1, records ++ prognostications}
    end)
  end
end
