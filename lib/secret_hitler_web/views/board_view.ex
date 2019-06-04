defmodule SecretHitlerWeb.BoardView do
  use SecretHitlerWeb, :view
  alias SecretHitler.{Board, Game}

  def power(nil), do: "None"
  def power(:policy_peek), do: "Peek"
  def power(:investigate_loyalty), do: "ID"
  def power(:special_election), do: "Election"
  def power(:execution), do: "Kill"
  def power(:fascist_victory), do: "Victory"
end
