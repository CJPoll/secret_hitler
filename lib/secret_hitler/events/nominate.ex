defmodule SecretHitler.Events.Nominate do
  defstruct [:player]
end

defimpl SecretHitler.Event, for: SecretHitler.Events.Nominate do
  alias SecretHitler.{Game, Events.Nominate}

  def apply(%Nominate{player: player}, %Game{} = game) do
    Game.nominate(game, player)
  end
end
