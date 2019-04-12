defmodule SecretHitler.Powers do
  @type player_count :: pos_integer
  @type fascist_card_count :: non_neg_integer

  @spec current_power(player_count, fascist_card_count) :: nil | term
  def current_power(_player_count, 0) do
    nil
  end

  def current_power(player_count, fascist_card_count)
      when player_count <= 6 and fascist_card_count < 3 do
    nil
  end

  def current_power(player_count, fascist_card_count)
      when player_count <= 8 and fascist_card_count < 2 do
    nil
  end

  def current_power(player_count, fascist_card_count)
      when player_count <= 8 and fascist_card_count == 0 do
    nil
  end

  def current_power(player_count, fascist_card_count)
      when player_count <= 6 and fascist_card_count == 3 do
    policy_peek()
  end

  def current_power(_player_count, fascist_card_count) when fascist_card_count in [4, 5] do
    execution()
  end

  def current_power(player_count, fascist_card_count)
      when player_count >= 9 and fascist_card_count == 1 do
    investigate_loyalty()
  end

  def current_power(player_count, fascist_card_count)
      when player_count >= 7 and fascist_card_count == 2 do
    investigate_loyalty()
  end

  def current_power(player_count, fascist_card_count)
      when player_count >= 7 and fascist_card_count == 3 do
    special_election()
  end

  def current_power(player_count, fascist_card_count)
      when player_count > 8 and fascist_card_count == 1 do
    investigate_loyalty()
  end

  def investigate_loyalty do
    :investigate_loyalty
  end

  def special_election do
    :special_election
  end

  def policy_peek do
    :policy_peek
  end

  def execution do
    :execution
  end
end
