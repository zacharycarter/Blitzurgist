defmodule Blitzurgist.Invoker do
  @moduledoc """
  The `Invoker` module initiates the GenStage pipeline and produces
  messages for the `Archmage` ConsumerSupervisor's consumers.
  """

  alias Blitzurgist.Reagents
  use GenStage

  require Logger

  @invoker __MODULE__

  def start_link(_) do
    GenStage.start_link(@invoker, :ok, name: @invoker)
  end

  def init(:ok) do
    Logger.debug("An invoker has created a summoning circle!")

    {:producer, {:queue.new(), 0}}
  end

  def handle_demand(demanded_invocations, {grimoire, pending_invocations}) do
    {rituals, invocations} =
      incant(grimoire, demanded_invocations + pending_invocations, [])

    {:noreply, rituals, invocations}
  end

  def invoke(reagents) when is_list(reagents) do
    GenStage.call(@invoker, {:invocation, reagents})
  end

  def invoke(reagents) do
    GenStage.call(@invoker, {:invocation, [reagents]})
  end

  def handle_call({:invocation, reagents}, invoker, {grimoire, pending_invocations}) do
    Logger.debug("The invoker has initiated a summoning ritual!")

    grimoire =
      Enum.reduce(reagents, grimoire, fn reagent, incantation ->
        reagent = Reagents.invoker(reagent, invoker)
        :queue.in(reagent, incantation)
      end)

    {rituals, invocations} = incant(grimoire, pending_invocations, [])

    {:noreply, rituals, invocations}
  end

  defp incant(grimoire, 0, rituals) do
    {Enum.reverse(rituals), {grimoire, 0}}
  end

  defp incant(grimoire, demanded_invocations, rituals) do
    case :queue.out(grimoire) do
      {{:value, ritual}, grimoire} ->
        incant(grimoire, demanded_invocations - 1, [ritual | rituals])

      {:empty, grimoire} ->
        {Enum.reverse(rituals), {grimoire, demanded_invocations}}
    end
  end
end
