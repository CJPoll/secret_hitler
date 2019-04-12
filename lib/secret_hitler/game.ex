defmodule SecretHitler.Game do
  defmodule TermLimit do
    defstruct [:president, :chancellor]

    def new, do: %__MODULE__{}

    def new(president, chancellor) do
      %__MODULE__{president: president, chancellor: chancellor}
    end
  end

  alias SecretHitler.{Board, Policy, Powers, Queue}

  @type player :: String.t()

  @type vote :: {player, :ja | :nein}

  defstruct [
    :board,
    :discards,
    :executed_players,
    :fascists,
    :hitler,
    :investigations,
    :nomination,
    :players,
    :queue,
    :special_president,
    :state,
    votes: %{},
    term_limits: TermLimit.new()
  ]

  def new(players) do
    SecretHitler.GameBuilder.new(players)
  end

  def current_player(%__MODULE__{queue: queue, special_president: president}) do
    president || Queue.peek(queue)
  end

  def discarding?(%__MODULE__{state: :president_discarding} = game, player) do
    player == current_player(game)
  end

  def discarding?(%__MODULE__{state: :chancellor_discarding, nomination: player}, player),
    do: true

  def discarding?(%__MODULE__{}, _player), do: false

  def eligible_for_investigation(%__MODULE__{players: players} = game) do
    (living_players(game) -- investigated_players(game)) -- [current_player(game)]
  end

  def eligible_for_execution(%__MODULE__{players: players} = game) do
    (players -- [current_player(game)]) --
      game.executed_players
  end

  def eligible_for_special_election(%__MODULE__{players: players} = game) do
    (players -- [current_player(game)]) -- game.executed_players
  end

  def eligible_for_nomination(%__MODULE__{state: :nominating_chancellor} = game) do
    players =
      living_players(game) --
        [current_player(game), game.term_limits.president, game.term_limits.chancellor]

    case players do
      [] -> living_players(game) -- [current_player(game)]
      other -> other
    end
  end

  def executed?(%__MODULE__{executed_players: players}, player) do
    player in players
  end

  def execution?(%__MODULE__{state: :execution} = game, player) do
    player == current_player(game)
  end

  def execution?(%__MODULE__{}, _player), do: false

  def living_players(%__MODULE__{players: players, executed_players: executed_players}) do
    players -- executed_players
  end

  def nominate(%__MODULE__{state: :nominating_chancellor} = game, chancellor) do
    if chancellor in game.players do
      %__MODULE__{game | nomination: chancellor, state: :electing_government}
    end
  end

  def nominating_chancellor?(%__MODULE__{state: :nominating_chancellor} = game, player) do
    player == current_player(game)
  end

  def nominating_chancellor?(%__MODULE__{}, _player), do: false

  def vote(%__MODULE__{state: :electing_government, votes: votes} = game, player, vote) do
    votes = Map.update(votes, player, vote, fn _ -> vote end)

    if living_players(game) -- Map.keys(votes) == [] do
      result = election_results(votes)
      game = %__MODULE__{game | votes: %{}}

      vote(game, result)
    else
      %__MODULE__{game | votes: votes}
    end
  end

  def vote(%__MODULE__{state: :electing_government} = game, :ja) do
    if hitler_victory?(game) do
      %__MODULE__{game | state: :fascist_victory}
    else
      president = Queue.peek(game.queue)
      board = Board.election_succeeded(game.board)
      term_limits = TermLimit.new(president, game.nomination)

      %__MODULE__{
        game
        | state: :president_discarding,
          board: board,
          term_limits: term_limits
      }
    end
  end

  def vote(%__MODULE__{state: :electing_government} = game, :nein) do
    term_limits =
      if game.board.failed_elections >= 2 do
        TermLimit.new()
      else
        game.term_limits
      end

    board = Board.election_failed(game.board)

    state =
      cond do
        Board.liberal_victory?(board) -> :liberal_victory
        Board.fascist_victory?(board) -> :fascist_victory
        true -> :nominating_chancellor
      end

    queue = Queue.rotate(game.queue)

    %__MODULE__{
      game
      | state: state,
        board: board,
        term_limits: term_limits,
        nomination: "",
        special_president: nil,
        queue: queue
    }
  end

  def policy_choices(%__MODULE__{state: :policy_peek} = game) do
    Board.peek(game.board, 3)
  end

  def policy_choices(%__MODULE__{state: :president_discarding} = game) do
    Board.peek(game.board, 3)
  end

  def policy_choices(%__MODULE__{state: :chancellor_discarding} = game) do
    Board.peek(game.board, 3) -- game.discards
  end

  def policy_peek?(%__MODULE__{state: :policy_peek} = game, player) do
    player == current_player(game)
  end

  def policy_peek?(%__MODULE__{}, _player), do: false

  def special_election?(%__MODULE__{state: :special_election} = game, player) do
    current_player(game) == player
  end

  def special_election?(%__MODULE__{}, _player), do: false

  def votes(%__MODULE__{state: :electing_government} = game, votes) when is_list(votes) do
    %{ja: ja, nein: nein} =
      Enum.reduce(votes, %{ja: 0, nein: 0}, fn {_player, vote}, acc ->
        increment_vote(acc, vote)
      end)

    if ja > nein do
      votes(game, :ja)
    else
      votes(game, :nein)
    end
  end

  def voting?(%__MODULE__{state: :electing_government} = game, player) do
    player not in game.executed_players
  end

  def voting?(%__MODULE__{} = game, player), do: false

  def hitler_victory?(%__MODULE__{hitler: hitler, nomination: hitler, board: board}) do
    Board.fascist_policies_enacted(board) >= 3
  end

  def hitler_victory?(%__MODULE__{}), do: false

  def discard(%__MODULE__{state: :president_discarding} = game, discarded_policy) do
    %__MODULE__{game | state: :chancellor_discarding, discards: [discarded_policy]}
  end

  def discard(%__MODULE__{state: :chancellor_discarding} = game, discarded_policy) do
    discards = [discarded_policy | game.discards]
    policies = Board.peek(game.board, 3)
    [%{team: team} = keep] = policies -- discards

    board = Board.commit(game.board, discards, keep)

    current_power =
      Powers.current_power(length(game.players), Board.fascist_policies_enacted(board))

    cond do
      Board.liberal_victory?(board) ->
        %__MODULE__{
          game
          | state: :liberal_victory,
            discards: [],
            board: board,
            queue: game.queue,
            nomination: nil
        }

      Board.fascist_victory?(board) ->
        %__MODULE__{
          game
          | state: :fascist_victory,
            discards: [],
            board: board,
            queue: game.queue,
            nomination: nil
        }

      "fascist" == team and not is_nil(current_power) ->
        %__MODULE__{
          game
          | state: current_power,
            discards: [],
            board: board,
            queue: game.queue,
            special_president: nil,
            nomination: nil
        }

      true ->
        %__MODULE__{
          game
          | state: :nominating_chancellor,
            special_president: nil,
            discards: [],
            board: board,
            queue: Queue.rotate(game.queue),
            nomination: nil
        }
    end
  end

  def end_peek(%__MODULE__{state: :policy_peek} = game) do
    %__MODULE__{game | state: :nominating_chancellor, queue: Queue.rotate(game.queue)}
  end

  def investigated_players(%__MODULE__{investigations: investigations}) do
    Enum.map(investigations, fn {_investigator, investigated} -> investigated end)
  end

  def team_for(%__MODULE__{fascists: fascists}, player) do
    if player in fascists do
      "fascist"
    else
      "liberal"
    end
  end

  def investigate(
        %__MODULE__{state: :investigate_loyalty, investigations: investigations} = game,
        investigated
      ) do
    investigator = current_player(game)

    %__MODULE__{
      game
      | investigations: [{investigator, investigated} | investigations],
        queue: Queue.rotate(game.queue),
        state: :nominating_chancellor
    }
  end

  def special_election(%__MODULE__{} = game, nominee) do
    %__MODULE__{
      game
      | special_president: nominee,
        state: :nominating_chancellor,
        queue: Queue.rotate(game.queue)
    }
  end

  def execute(%__MODULE__{state: :execution, queue: queue} = game, player) do
    %__MODULE__{
      game
      | state: :nominating_chancellor,
        queue: queue |> Queue.drop(player) |> Queue.rotate(),
        executed_players: [player | game.executed_players]
    }
  end

  defp increment_vote(acc, key) do
    Map.update(acc, key, 1, &(&1 + 1))
  end

  defp election_results(votes) do
    {ja, nein} =
      votes
      |> Map.values()
      |> Enum.reduce({0, 0}, fn
        "ja", {ja, nein} ->
          {ja + 1, nein}

        "nein", {ja, nein} ->
          {ja, nein + 1}
      end)

    if ja > nein, do: :ja, else: :nein
  end
end
