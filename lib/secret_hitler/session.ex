defmodule SecretHitler.Session do
  alias SecretHitler.{Game, GameSetup}

  defstruct [
    :game,
    :name,
    :owner,
    game_setup: GameSetup.new(),
    hosts: %{}
  ]

  def new(name) do
    %__MODULE__{name: name}
  end

  def add_player(
        %__MODULE__{hosts: hosts, game_setup: setup, game: nil} = session,
        player,
        host_id
      ) do
    hosts = Map.update(hosts, host_id, player, fn _ -> player end)
    %__MODULE__{session | game_setup: GameSetup.add_player(setup, player), hosts: hosts}
  end

  def add_player(%__MODULE__{} = session, _player), do: session

  def game_started?(%__MODULE__{game: nil}), do: false
  def game_started?(%__MODULE__{game: %Game{}}), do: true

  def owner(%__MODULE__{owner: owner} = session) do
    player_name(session, owner)
  end

  def owner(%__MODULE__{} = session, owner) do
    %__MODULE__{session | owner: owner}
  end

  def player_name(%__MODULE__{hosts: hosts}, host_id) do
    hosts[host_id]
  end

  def start(%__MODULE__{game: nil} = session) do
    %__MODULE__{session | game_setup: GameSetup.to_game(session.setup)}
  end

  def kick(%__MODULE__{game: nil, game_setup: game_setup, hosts: hosts} = session, player) do
    game_setup = GameSetup.remove_player(game_setup, player)

    hosts =
      hosts
      |> Enum.reject(fn {_k, v} -> v == player end)
      |> Map.new()

    %__MODULE__{session | game_setup: game_setup, hosts: hosts}
  end

  def kick(%__MODULE__{} = session, _player), do: session

  def move_down(%__MODULE__{game: nil, game_setup: game_setup} = session, player) do
    %__MODULE__{session | game_setup: GameSetup.move_down(game_setup, player)}
  end

  def move_up(%__MODULE__{game: nil, game_setup: game_setup} = session, player) do
    %__MODULE__{session | game_setup: GameSetup.move_up(game_setup, player)}
  end

  def players(%__MODULE__{game: nil, game_setup: game_setup}) do
    game_setup.players
  end

  def players(%__MODULE__{game: game}) do
    game.players
  end

  def game_function(%__MODULE__{game: %Game{} = game} = session, function, args) do
    game = apply(Game, function, [game | args])
    %__MODULE__{session | game: game}
  end

  def start_game(%__MODULE__{} = session) do
    game = GameSetup.to_game(session.game_setup)
    %__MODULE__{session | game: game}
  end
end
