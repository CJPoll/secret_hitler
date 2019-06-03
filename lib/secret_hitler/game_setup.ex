defmodule SecretHitler.GameSetup do
  defstruct players: []

  def new() do
    %__MODULE__{}
  end

  def add_player(%__MODULE__{players: players}, player) do
    players = Enum.uniq([player | players])
    %__MODULE__{players: players}
  end

  def to_game(%__MODULE__{players: players}) do
    SecretHitler.GameBuilder.new(players)
  end

  def remove_player(%__MODULE__{players: players}, player) do
    players = Enum.reject(players, &(&1 == player))
    %__MODULE__{players: players}
  end

  def move_up(%__MODULE__{players: players} = setup, player) do
    case Enum.find_index(players, &(&1 == player)) do
      0 ->
        setup

      index ->
        players =
          players
          |> List.delete_at(index)
          |> List.insert_at(index - 1, player)

        %__MODULE__{players: players}
    end
  end

  def move_down(%__MODULE__{players: players} = setup, player) do
    case Enum.find_index(players, &(&1 == player)) do
      index when index == length(players) - 1 ->
        setup

      index ->
        players =
          players
          |> List.delete_at(index)
          |> List.insert_at(index + 1, player)

        %__MODULE__{players: players}
    end
  end
end
