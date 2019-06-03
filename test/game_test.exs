defmodule SecretHitler.Game.Test do
  use ExUnit.Case

  alias SecretHitler.{Board, Event, Events, Game}

  alias SecretHitler.Event
  alias SecretHitler.Events.{Discard, Nominate, Vote}

  @player_list [
    "player1",
    "player2",
    "player3",
    "player4",
    "player5"
  ]

  defp player1, do: "player1"
  defp player2, do: "player2"
  defp player3, do: "player3"
  defp player4, do: "player4"
  defp player5, do: "player5"

  setup do
    game = Game.new(@player_list)

    {:ok, %{game: game}}
  end

  describe "new/1" do
    test "returns a %Game{}" do
      assert %Game{} = Game.new(@player_list)
    end

    test "first player in the player list has first turn", %{game: game} do
      assert Game.current_player(game) == player1()
    end
  end

  describe "nominate/2" do
    test "puts the given player as chancellor", %{game: game} do
      chancellor =
        game
        |> Game.nominate(player2())
        |> Game.chancellor()

      assert chancellor == player2()
    end

    test "changes game state from :nominating_chancellor to :electing_government", %{game: game} do
      assert Game.nominating_chancellor?(game)
      refute Game.voting?(game)

      game = Game.nominate(game, player2())

      refute Game.nominating_chancellor?(game)
      assert Game.voting?(game)
    end

    test "ignores a nomination if the nominee is ineligible", %{game: game} do
      assert Game.nominating_chancellor?(game)
      refute Game.voting?(game)

      game2 = Game.nominate(game, player1())

      assert Game.nominating_chancellor?(game2)
      refute Game.voting?(game2)

      assert game == game2
    end

    test "ignores a nomination if the game is not in the nominating state", %{game: game} do
      game = Game.nominate(game, player2())

      refute Game.nominating_chancellor?(game)

      game2 = Game.nominate(game, player3())

      refute Game.nominating_chancellor?(game)
      # Assert that the second nomination had no effect
      assert game == game2
    end
  end

  describe "vote/3" do
    setup :game_in_voting_phase

    test "casting final vote changes state from voting to president discarding on success", %{
      game: game
    } do
      assert @player_list
             |> Events.vote("ja")
             |> Events.apply(game)
             |> Game.president_discarding?()
    end

    test "casting final vote changes state from voting to nominating_chancellor on failure", %{
      game: game
    } do
      assert @player_list
             |> Events.vote("nein")
             |> Events.apply(game)
             |> Game.nominating_chancellor?()
    end

    test "a player can change their vote until the last vote is cast", %{game: game} do
      assert Game.player_vote(game, player1()) == nil
      game = Game.vote(game, player1(), "ja")
      assert Game.player_vote(game, player1()) == "ja"
      game = Game.vote(game, player1(), "nein")
      assert Game.player_vote(game, player1()) == "nein"
    end

    test "a failed election increases the failed election count", %{game: game} do
      assert Board.failed_elections(game.board) == 0

      game =
        @player_list
        |> Events.vote("nein")
        |> Events.apply(game)

      assert Board.failed_elections(game.board) == 1
    end

    test "3 failed elections causes a flip", %{game: game} do
      assert Board.failed_elections(game.board) == 0
      assert Board.draw_pile_size(game.board) == 17
      assert Board.discard_pile_size(game.board) == 0
      assert Board.fascist_policies_enacted(game.board) == 0
      assert Board.liberal_policies_enacted(game.board) == 0

      game = three_failed_elections(game)

      assert Board.failed_elections(game.board) == 0
      assert Board.draw_pile_size(game.board) == 16
      assert Board.discard_pile_size(game.board) == 0

      assert Board.fascist_policies_enacted(game.board) == 1 or
               Board.liberal_policies_enacted(game.board) == 1

      assert Board.fascist_policies_enacted(game.board) == 0 or
               Board.liberal_policies_enacted(game.board) == 0
    end

    test "3 failed elections causes term limits to disappear", %{game: game} do
      game =
        @player_list
        |> Events.vote("ja")
        |> Events.apply(game)

      events = [Events.discard(0), Events.discard(0)]

      game = Event.apply(events, game)

      # This is a 5 player game, which means president is eligible for
      # reelection
      assert Game.eligible_for_nomination?(game, player1())
      refute Game.eligible_for_nomination?(game, player2())
      assert Game.eligible_for_nomination?(game, player3())
      assert Game.eligible_for_nomination?(game, player4())
      assert Game.eligible_for_nomination?(game, player5())

      events = [
        Events.nominate(player1()),
        Events.vote(@player_list, "nein"),
        Events.nominate(player1()),
        Events.vote(@player_list, "nein"),
        Events.nominate(player1()),
        Events.vote(@player_list, "nein")
      ]

      game = Event.apply(events, game)

      assert Game.eligible_for_nomination?(game, player1())
      assert Game.eligible_for_nomination?(game, player2())
      assert Game.eligible_for_nomination?(game, player3())
      assert Game.eligible_for_nomination?(game, player4())
      # Player 5 can't nominate themselves
      refute Game.eligible_for_nomination?(game, player5())
    end
  end

  ### Game Setup

  defp game_in_voting_phase(%{game: game} = context) do
    actions = [%Nominate{player: player2()}]

    game = Event.apply(actions, game)
    {:ok, %{context | game: game}}
  end

  defp three_failed_elections(game) do
    events =
      @player_list
      |> Enum.reduce([], fn player, events ->
        [%Vote{player: player, vote: "nein"} | events]
      end)
      |> List.insert_at(0, %Nominate{player: player4()})

    events =
      @player_list
      |> Enum.reduce(events, fn player, events ->
        [%Vote{player: player, vote: "nein"} | events]
      end)
      |> List.insert_at(0, %Nominate{player: player4()})

    events =
      Enum.reduce(@player_list, events, fn player, events ->
        [%Vote{player: player, vote: "nein"} | events]
      end)

    Event.apply(events, game)
  end
end
