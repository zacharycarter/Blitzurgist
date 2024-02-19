defmodule InvokerTest do
  use ExUnit.Case, async: true

  alias Blitzurgist.Invoker
  alias Blitzurgist.Reagents

  test "produces invocations" do
    reagents =
      []
      |> Enum.into(%{})
      |> Reagents.defaults()
      |> Reagents.region("na1")
      |> Reagents.incantation("blitz", "na1")

    assert [
             "charles_kean",
             "fineapril",
             "kmadkilla",
             "mushygas22",
             "on_jahseh",
             "rift_heraid",
             "skysoap",
             "supportive_main",
             "tribadism"
           ] == Invoker.invoke(reagents)
  end
end
