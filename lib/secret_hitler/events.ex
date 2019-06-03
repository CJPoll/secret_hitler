defprotocol SecretHitler.Event do
  alias SecretHitler.Game

  @type t :: term

  @spec apply(t, Game.t()) :: Game.t()
  def apply(event, game)
end

defimpl SecretHitler.Event, for: List do
  alias SecretHitler.Game

  def apply(events, %Game{} = game) do
    Enum.reduce(events, game, &SecretHitler.Event.apply/2)
  end
end

defmodule SecretHitler.Events do
  alias SecretHitler.Events.{Discard, Nominate, Vote}

  defdelegate apply(event, game), to: SecretHitler.Event

  def discard(index) when is_integer(index) do
    %Discard{index: index}
  end

  def discard(team) when is_binary(team) do
    %Discard{team: team}
  end

  def nominate(player) do
    %Nominate{player: player}
  end

  def vote(player, vote) when is_binary(player) do
    %Vote{player: player, vote: vote}
  end

  def vote(players, vote) when is_list(players) do
    Enum.map(players, fn player -> vote(player, vote) end)
  end
end
