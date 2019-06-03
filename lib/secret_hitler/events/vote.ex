defmodule SecretHitler.Events.Vote do
  defstruct [:player, :vote]
end

defimpl SecretHitler.Event, for: SecretHitler.Events.Vote do
  alias SecretHitler.{Game, Events.Vote}

  def apply(%Vote{player: player, vote: vote}, %Game{} = game) do
    Game.vote(game, player, vote)
  end
end
