defmodule SecretHitler.GameBuilder do
  alias SecretHitler.{Board, Game, Queue}

  defguardp is_even(count) when is_integer(count) and rem(count, 2) == 0
  defguardp is_odd(count) when is_integer(count) and rem(count, 2) == 1

  def new(players) when is_list(players) and length(players) >= 5 do
    player_queue = Queue.new(players)
    fascists = pick_fascists(players)
    hitler = pick_hitler(fascists)

    %Game{
      board: Board.new(length(players)),
      discards: [],
      executed_players: [],
      fascists: fascists,
      hitler: hitler,
      investigations: [],
      players: players,
      queue: player_queue,
      state: :nominating_chancellor
    }
  end

  def liberal_count(player_count) do
    div(player_count, 2) + 1
  end

  def fascist_count(player_count) when is_even(player_count) do
    div(player_count, 2) - 1
  end

  def fascist_count(player_count) when is_odd(player_count) do
    div(player_count, 2)
  end

  def pick_fascists(players) do
    count = fascist_count(length(players))
    Enum.take_random(players, count)
  end

  def pick_hitler(fascists) do
    Enum.random(fascists)
  end
end
