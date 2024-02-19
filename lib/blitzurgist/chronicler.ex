defmodule Blitzurgist.Chronicler do
  @moduledoc """
  The `Chronicler` is supervised by the `Prophet` module and consumes messages
  from the `Seer` module. It is responsible for forwarding these messages to the
  `Abjurer` which is the final consumer in the GenStage pipeline.
  """

  use GenStage

  require Logger

  alias Blitzurgist.Abjurer

  def start_link(revelation) do
    GenStage.start_link(__MODULE__, revelation)
  end

  def init(revelation) do
    Abjurer.start_link(revelation, self())

    send(self(), {:recount, revelation})
    {:producer, {:queue.new(), 0}}
  end

  def handle_demand(demanded_recountings, {grimoire, pending_recountings}) do
    {recountings, chronicle} = archive(grimoire, demanded_recountings + pending_recountings, [])
    {:noreply, recountings, chronicle}
  end

  def handle_info({:recount, revelation}, {grimoire, pending_recountings}) do
    Logger.debug(
      "A chronicler has received a revelation from the prophet and is encoding it into the compendium!"
    )

    grimoire = :queue.in(revelation, grimoire)

    {recountings, chronicle} = archive(grimoire, pending_recountings, [])

    {:noreply, recountings, chronicle}
  end

  defp archive(grimoire, 0, recountings) do
    {Enum.reverse(recountings), {grimoire, 0}}
  end

  defp archive(grimoire, demanded_recountings, recountings) do
    case :queue.out(grimoire) do
      {{:value, recounting}, grimoire} ->
        archive(grimoire, demanded_recountings - 1, [recounting | recountings])

      {:empty, grimoire} ->
        {Enum.reverse(recountings), {grimoire, demanded_recountings}}
    end
  end
end
