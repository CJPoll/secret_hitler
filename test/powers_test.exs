defmodule SecretHitler.Powers.Test do
  use ExUnit.Case

  @test_module SecretHitler.Powers

  describe "5-6 players" do
    @player_count 5
    test "5 players returns correct values" do
      assert nil == @test_module.current_power(@player_count, 0)
      assert nil == @test_module.current_power(@player_count, 1)
      assert nil == @test_module.current_power(@player_count, 2)
      assert @test_module.policy_peek() == @test_module.current_power(@player_count, 3)
      assert @test_module.execution == @test_module.current_power(@player_count, 4)
      assert @test_module.execution == @test_module.current_power(@player_count, 5)
      assert @test_module.fascist_victory == @test_module.current_power(@player_count, 6)
    end

    @player_count 6
    test "6 players returns correct values" do
      assert nil == @test_module.current_power(@player_count, 0)
      assert nil == @test_module.current_power(@player_count, 1)
      assert nil == @test_module.current_power(@player_count, 2)
      assert @test_module.policy_peek() == @test_module.current_power(@player_count, 3)
      assert @test_module.execution == @test_module.current_power(@player_count, 4)
      assert @test_module.execution == @test_module.current_power(@player_count, 5)
      assert @test_module.fascist_victory == @test_module.current_power(@player_count, 6)
    end
  end

  describe "7-8 players" do
    @player_count 7
    test "7 players returns correct values" do
      assert nil == @test_module.current_power(@player_count, 0)
      assert nil == @test_module.current_power(@player_count, 1)
      assert @test_module.investigate_loyalty() == @test_module.current_power(@player_count, 2)
      assert @test_module.special_election() == @test_module.current_power(@player_count, 3)
      assert @test_module.execution == @test_module.current_power(@player_count, 4)
      assert @test_module.execution == @test_module.current_power(@player_count, 5)
      assert @test_module.fascist_victory == @test_module.current_power(@player_count, 6)
    end

    @player_count 8
    test "8 players returns correct values" do
      assert nil == @test_module.current_power(@player_count, 0)
      assert nil == @test_module.current_power(@player_count, 1)
      assert @test_module.investigate_loyalty() == @test_module.current_power(@player_count, 2)
      assert @test_module.special_election() == @test_module.current_power(@player_count, 3)
      assert @test_module.execution == @test_module.current_power(@player_count, 4)
      assert @test_module.execution == @test_module.current_power(@player_count, 5)
      assert @test_module.fascist_victory == @test_module.current_power(@player_count, 6)
    end
  end

  describe "9-10 players" do
    @player_count 9
    test "9 players returns correct values" do
      assert nil == @test_module.current_power(@player_count, 0)
      assert @test_module.investigate_loyalty() == @test_module.current_power(@player_count, 1)
      assert @test_module.investigate_loyalty() == @test_module.current_power(@player_count, 2)
      assert @test_module.special_election() == @test_module.current_power(@player_count, 3)
      assert @test_module.execution == @test_module.current_power(@player_count, 4)
      assert @test_module.execution == @test_module.current_power(@player_count, 5)
      assert @test_module.fascist_victory == @test_module.current_power(@player_count, 6)
    end

    @player_count 10
    test "10 players returns correct values" do
      assert nil == @test_module.current_power(@player_count, 0)
      assert @test_module.investigate_loyalty() == @test_module.current_power(@player_count, 1)
      assert @test_module.investigate_loyalty() == @test_module.current_power(@player_count, 2)
      assert @test_module.special_election() == @test_module.current_power(@player_count, 3)
      assert @test_module.execution == @test_module.current_power(@player_count, 4)
      assert @test_module.execution == @test_module.current_power(@player_count, 5)
      assert @test_module.fascist_victory == @test_module.current_power(@player_count, 6)
    end
  end
end
