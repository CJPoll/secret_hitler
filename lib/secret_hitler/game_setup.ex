defmodule SecretHitler.GameSetup do
  defstruct players: []

  def new() do
    %__MODULE__{}
  end

  def add_player(%__MODULE__{players: players}, player) do
    %__MODULE__{players: [player | players]}
  end

  def to_game(%__MODULE__{players: players}) do
    SecretHitler.GameBuilder.new(players)
  end
end
