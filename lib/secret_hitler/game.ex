defmodule SecretHitler.Game do
  defmodule TermLimit do
    @moduledoc false
    defstruct [:president, :chancellor]

    def new, do: %__MODULE__{}

    def new(president, chancellor) do
      %__MODULE__{president: president, chancellor: chancellor}
    end
  end

  alias SecretHitler.{Board, Powers, Queue}

  @type player :: String.t()
  @type investigator :: player
  @type investigated :: player
  @type role_text :: String.t()
  @type state ::
          :nominating_chancellor
          | :electing_government
          | :president_discarding
          | :chancellor_discarding
          | :liberal_victory
          | :fascist_victory
          | :investigate_loyalty
          | :special_election
          | :policy_peek
          | :execution

  @type vote :: :ja | :nein
  @typedoc """
  The same as a `t:vote/0`, but as a String.t instead of an atom
  """
  @type vote_string :: String.t()

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

  @type t :: %__MODULE__{
          board: Board.t(),
          discards: [Policy.t()],
          executed_players: [player],
          fascists: [player],
          hitler: player,
          investigations: [{investigator, investigated}],
          nomination: player | nil,
          players: [player],
          queue: Queue.t(),
          special_president: player | nil,
          state: state,
          votes: %{player => vote},
          term_limits: %TermLimit{}
        }

  @doc """
  Given a list of players, returns a new game with turn order respecting the
  order of players in the list.
  """
  @spec new([player]) :: t
  def new(players) do
    SecretHitler.GameBuilder.new(players)
  end

  @spec chancellor(t) :: player | nil
  def chancellor(%__MODULE__{nomination: nomination}), do: nomination

  @doc """
  If the game is in the `:chancellor_discarding` state, returns `true`.
  Otherwise returns `false`.
  """
  @spec chancellor_discarding?(t) :: boolean
  def chancellor_discarding?(%__MODULE__{state: state}), do: state == :chancellor_discarding

  @doc """
  If the game currently has a president from the executive powers, returns that president.
  Otherwise returns the current player based on turn order.
  """
  @spec current_player(t) :: player
  def current_player(%__MODULE__{queue: queue, special_president: special_president}) do
    special_president || Queue.peek(queue)
  end

  defdelegate president(game), to: __MODULE__, as: :current_player

  @doc """
  If the game is in the `:president_discarding` state AND the given player is
  the president, returns `true`.
  If the game is in the `:chancellor_discarding` state AND the given player is
  the chancellor, returns `true`.
  Otherwise returns `false`.
  """
  @spec discarding?(t, player) :: boolean
  def discarding?(%__MODULE__{state: :president_discarding} = game, player) do
    player == current_player(game)
  end

  def discarding?(%__MODULE__{state: :chancellor_discarding, nomination: player}, player),
    do: true

  def discarding?(%__MODULE__{}, _player), do: false

  @doc """
  Returns a list of players who are eligible for investigation.

  A player is eligible for investigation if all of the following are true:
    - The player has not been executed
    - The player has not yet been investigated
    - The player is not the investigator
  """
  @spec eligible_for_investigation(t) :: [player]
  def eligible_for_investigation(%__MODULE__{} = game) do
    game
    |> living_players
    |> without_current_player(game)
    |> without_investigated_players(game)
  end

  @doc """
  Returns a list of players who are eligible for execution.

  A player is eligible for execution if all the following are true:

    - The player has not yet been executed
    - The player is not the executioner

  Note that the rules explicitly say a player can not kill themselves.
  """
  @spec eligible_for_execution(t) :: [player]
  def eligible_for_execution(%__MODULE__{} = game) do
    game
    |> living_players
    |> without_current_player(game)
  end

  @doc """
  Returns a list of players who are eligible for special election.

  A player is eligible for special election if all the following are true:
    - The player is not executed
    - The player is not the current president
  """
  @spec eligible_for_special_election(t) :: [player]
  def eligible_for_special_election(%__MODULE__{} = game) do
    game
    |> living_players
    |> Enum.reject(&(&1 == current_player(game)))
  end

  @doc """
  Returns a list of players who are eligible for nomination as chancellor.

  A player is ineligible for special election if _any_ of the following are true:
    - The player has been executed
    - The player is the current nominator
    - The player was president in the last government AND the government has not
      been thrown in chaos since
    - There are 5 or fewer players AND the player was chancellor in the last
      government AND the government has not been thrown in chaos since
  """
  @spec eligible_for_nomination(t) :: [player]
  def eligible_for_nomination(%__MODULE__{state: :nominating_chancellor} = game) do
    if living_player_count(game) > 5 do
      living_players(game) --
        [current_player(game), game.term_limits.president, game.term_limits.chancellor]
    else
      living_players(game) --
        [current_player(game), game.term_limits.chancellor]
    end
  end

  @doc """
  Returns `true` if the given player is eligible for nomination, regardless of
  current game state.
  Returns `false` otherwise.
  """
  @spec eligible_for_nomination?(t, player) :: boolean
  def eligible_for_nomination?(%__MODULE__{} = game, player) do
    eligible =
      if living_player_count(game) > 5 do
        living_players(game) --
          [current_player(game), game.term_limits.president, game.term_limits.chancellor]
      else
        living_players(game) --
          [current_player(game), game.term_limits.chancellor]
      end

    player in eligible
  end

  @doc """
  If the given player has been executed, returns `true`.
  Otherwise returns `false`.
  """
  @spec executed?(t, player) :: boolean
  def executed?(%__MODULE__{executed_players: players}, player) do
    player in players
  end

  @doc """
  If the game is in the `:execution` state, returns `true`.
  Otherwise returns `false`.
  """
  @spec execution?(t) :: boolean
  def execution?(%__MODULE__{state: state}), do: state == :execution

  @doc """
  If the game is in the `:execution` state AND the given player is the
  executioner, returns `true`.
  Otherwise returns `false`.
  """
  @spec execution?(t, player) :: boolean
  def execution?(%__MODULE__{state: :execution} = game, player) do
    player == current_player(game)
  end

  def execution?(%__MODULE__{}, _player), do: false

  @doc """
  Returns a list of all players who are fascist, _including Hitler_.
  """
  @spec fascists(t) :: [player]
  def fascists(%__MODULE__{fascists: fascists}), do: fascists

  @doc """
  If the given player is a fascist (including Hitler), returns `true`.
  Otherwise returns `false`.
  """
  @spec fascist?(t, player) :: boolean
  def fascist?(%__MODULE__{} = game, player) do
    player in game.fascists
  end

  @doc """
  If the given player is Hitler, returns `true`.
  Otherwise returns `false`.
  """
  @spec hitler?(t, player) :: boolean
  def hitler?(%__MODULE__{} = game, player) do
    player == game.hitler
  end

  @doc """
  If the game is in the `:investigate_loyalty` phase AND the given player is the
  investigator, returns `true`.
  Otherwise returns `false`.
  """
  @spec investigate_loyalty?(t, player) :: boolean
  def investigate_loyalty?(%__MODULE__{state: :investigate_loyalty} = game, player) do
    player == current_player(game)
  end

  def investigate_loyalty?(%__MODULE__{}, _player), do: false

  @doc """
  If the given player is a liberal, returns `true`.
  Otherwise returns `false`.
  """
  @spec liberal?(t, player) :: boolean
  def liberal?(%__MODULE__{} = game, player) do
    player not in game.fascists
  end

  @doc """
  Returns a list of players who have _not_ been executed.
  """
  @spec living_players(t) :: [player]
  def living_players(%__MODULE__{players: players, executed_players: executed_players}) do
    players -- executed_players
  end

  @doc """
  Returns the count of players who have not been executed.
  """
  @spec living_player_count(t) :: non_neg_integer
  def living_player_count(%__MODULE__{} = game) do
    game
    |> living_players
    |> length
  end

  @doc """
  If the game is in the `:nominating_chancellor` state and the given player is
  eligible for nomination as chancellor, the player is added to the government
  nomination and the game transitions to the `:electing_government` state.

  If the game is not in the `:nominating_chancellor` state, the game is returned
  with no modification.
  """
  @spec nominate(t, player) :: t
  def nominate(%__MODULE__{state: :nominating_chancellor} = game, player) do
    if player in eligible_for_nomination(game) do
      %__MODULE__{game | nomination: player, state: :electing_government, votes: %{}}
    else
      game
    end
  end

  def nominate(%__MODULE__{} = game, _player), do: game

  @doc """
  Returns `true` if the game is in the `:nominating_chancellor` state.
  Returns `false` otherwise
  """
  @spec nominating_chancellor?(t) :: boolean
  def nominating_chancellor?(%__MODULE__{state: :nominating_chancellor}), do: true
  def nominating_chancellor?(%__MODULE__{}), do: false

  @doc """
  If the game is in the `:nominating_chancellor` state and the given player is
  the nominator, returns `true`.
  Otherwise returns `false`.
  """
  @spec nominating_chancellor?(t, player) :: boolean
  def nominating_chancellor?(%__MODULE__{state: :nominating_chancellor} = game, player) do
    player == current_player(game)
  end

  def nominating_chancellor?(%__MODULE__{}, _player), do: false

  @doc """
  If the given player is hitler, returns `"hitler"`.
  If the given player is fascist, returns `"a fascist"`.
  If the given player is a liberal, returns `"a liberal"`.
  Otherwise returns `"a spectator"`.
  """
  @spec role(t, player) :: role_text
  def role(%__MODULE__{} = game, player) do
    cond do
      hitler?(game, player) -> "hitler"
      fascist?(game, player) -> "a fascist"
      liberal?(game, player) -> "a liberal"
      true -> "a spectator"
    end
  end

  @doc """
  If the game is in the `:president_discarding` state, returns `true`.
  Otherwise returns `false`.
  """
  @spec president_discarding?(t) :: boolean
  def president_discarding?(%__MODULE__{state: state}), do: state == :president_discarding

  @doc """
  If the game is in the `:president_nominating` state, returns `true`.
  Otherwise returns `false`.
  """
  @spec president_discarding?(t) :: boolean
  def president_nominating?(%__MODULE__{state: state}), do: state == :nominating_chancellor

  @doc """
  If the given player is a spectator (i.e. is `nil`), returns `true`.
  Otherwise returns `false`.
  """
  @spec spectator?(t, player | nil) :: boolean
  def spectator?(%__MODULE__{}, nil), do: true
  def spectator?(%__MODULE__{}, _), do: false

  def vote(%__MODULE__{state: :electing_government, votes: votes} = game, player, vote) do
    votes = Map.update(votes, player, vote, fn _ -> vote end)
    game = %__MODULE__{game | votes: votes}

    cond do
      everyone_voted?(game) and election_results(votes) == :ja ->
        election_succeeded(game)

      everyone_voted?(game) and election_results(votes) == :nein ->
        election_failed(game)

      true ->
        game
    end
  end

  @doc false
  def election_succeeded(%__MODULE__{state: :electing_government} = game) do
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

  @doc false
  def election_failed(%__MODULE__{state: :electing_government} = game) do
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

  def vote(%__MODULE__{} = game, _) do
    game
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

  def policy_peek?(%__MODULE__{state: state}), do: state == :policy_peek

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

  def voting?(%__MODULE__{state: state}), do: state == :electing_government

  def voting?(%__MODULE__{state: :electing_government} = game, player) do
    player not in game.executed_players
  end

  def voting?(%__MODULE__{}, _player), do: false

  @doc """
  Returns `true` if the hitler victory condition is in effect. This occurs when all
  the following are true:

  - At least 3 fascist policies have been played on the board
  - Hitler is elected as chancellor

  Returns `false` otherwise.
  """
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

  @doc false
  def end_peek(%__MODULE__{state: :policy_peek} = game) do
    %__MODULE__{game | state: :nominating_chancellor, queue: Queue.rotate(game.queue)}
  end

  @doc """
  Returns a (possibly empty) list of all players who have been investigated.
  """
  @spec investigated_players(t) :: [player]
  def investigated_players(%__MODULE__{investigations: investigations}) do
    investigations
    |> Enum.map(fn {_investigator, investigated} -> investigated end)
  end

  @doc """
  Returns a (possibly empty) list of all players that the given player has investigated.
  """
  @spec investigated_players(t, player) :: [player]
  def investigated_players(%__MODULE__{investigations: investigations}, investigator) do
    investigations
    |> Enum.filter(fn
      {^investigator, _} -> true
      _ -> false
    end)
    |> Enum.map(fn {_investigator, investigated} -> investigated end)
  end

  def team_for(%__MODULE__{fascists: fascists}, player) do
    if player in fascists do
      "fascist"
    else
      "liberal"
    end
  end

  @doc """
  Investigates the party status of a player if the game is in the
  `:investigate_loyalty` state. This transitions the game to the
  `:nominating_chancellor` state.
  """
  @spec investigate(t, player) :: t
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

  @doc """
  Executes the given player if the game is in the `:execution` state, and
  transitions the game to the `:nominating_chancellor` state.

  Returns the game unmodified otherwise.
  """
  @spec execute(t, player) :: t
  def execute(%__MODULE__{state: :execution, queue: queue} = game, player) do
    %__MODULE__{
      game
      | state: :nominating_chancellor,
        queue: queue |> Queue.drop(player) |> Queue.rotate(),
        executed_players: [player | game.executed_players]
    }
  end

  def execute(%__MODULE__{} = game, _player), do: game

  @doc """
  Returns `true` if a player has ever been investigated by another player.
  Returns `false` otherwise.
  """
  @spec investigated?(t, player) :: boolean
  def investigated?(%__MODULE__{} = game, player) do
    player in investigated_players(game)
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

  defp without_current_player(players, game) when is_list(players) do
    Enum.reject(players, fn player -> player == current_player(game) end)
  end

  defp without_investigated_players(players, game) when is_list(players) do
    Enum.reject(players, fn player -> investigated?(game, player) end)
  end

  defp everyone_voted?(%__MODULE__{} = game) do
    living_players =
      game
      |> living_players
      |> MapSet.new()

    players_who_voted =
      game
      |> players_who_voted
      |> MapSet.new()

    MapSet.intersection(living_players, players_who_voted) == living_players
  end

  defp players_who_voted(%__MODULE__{votes: votes}) do
    Map.keys(votes)
  end

  def player_voted?(%__MODULE__{} = game, player) do
    player in players_who_voted(game)
  end

  def waiting_on_vote(%__MODULE__{} = game) do
    living_players(game) -- players_who_voted(game)
  end

  @doc """
  For the current election:

    - Returns `"ja"` if the given player voted ja.
    - Returns `"nein"` if the given player voted ja.
    - Returns `nil` if the player has not yet voted
  """
  @spec player_vote(t, player) :: vote_string | nil
  def player_vote(%__MODULE__{votes: votes}, player) do
    votes[player]
  end

  def votes(%__MODULE__{votes: votes} = game) do
    votes
  end

  def total_player_count(%__MODULE__{players: players}) do
    length(players)
  end
end
