defmodule SecretHitler.Board do
  alias SecretHitler.{PolicyDeck, Policy}

  defstruct [
    :policy_deck,
    fascist_policies_enacted: 0,
    liberal_policies_enacted: 0,
    failed_elections: 0
  ]

  @type t :: %__MODULE__{}

  def new do
    %__MODULE__{policy_deck: PolicyDeck.starting_deck()}
  end

  def complete?(%__MODULE__{} = board) do
    fascist_policies_enacted(board) >= 6 or liberal_policies_enacted(board) >= 5
  end

  def victor(%__MODULE__{} = board) do
    cond do
      fascist_policies_enacted(board) >= 6 -> :fascist
      liberal_policies_enacted(board) >= 5 -> :liberal
      true -> nil
    end
  end

  def liberal_victory?(%__MODULE__{} = board) do
    liberal_policies_enacted(board) >= 5
  end

  def fascist_victory?(%__MODULE__{} = board) do
    fascist_policies_enacted(board) >= 6
  end

  def fascist_policies_enacted(%__MODULE__{fascist_policies_enacted: count}), do: count
  def liberal_policies_enacted(%__MODULE__{liberal_policies_enacted: count}), do: count
  def failed_elections(%__MODULE__{failed_elections: count}), do: count

  def draw_pile_size(%__MODULE__{policy_deck: policy_deck}) do
    PolicyDeck.draw_pile_size(policy_deck)
  end

  def discard_pile_size(%__MODULE__{policy_deck: policy_deck}) do
    PolicyDeck.discard_pile_size(policy_deck)
  end

  def peek(%__MODULE__{policy_deck: deck}, count) do
    PolicyDeck.peek(deck, count)
  end

  def election_failed(%__MODULE__{policy_deck: deck, failed_elections: 2} = board) do
    [card] = PolicyDeck.peek(deck, 1)
    board = %__MODULE__{board | failed_elections: 0, policy_deck: PolicyDeck.pop(deck, 1)}

    board
    |> play_policy(card)
    |> shuffle
  end

  def election_failed(%__MODULE__{failed_elections: count} = board) do
    %__MODULE__{board | failed_elections: count + 1}
  end

  def election_succeeded(%__MODULE__{} = board) do
    %__MODULE__{board | failed_elections: 0}
  end

  def shuffle(%__MODULE__{policy_deck: deck} = board) do
    if draw_pile_size(board) < 3 do
      deck = PolicyDeck.shuffle(deck)
      %__MODULE__{board | policy_deck: deck}
    else
      board
    end
  end

  def commit(%__MODULE__{policy_deck: deck} = board, _discards = [l, r], keep) do
    deck =
      deck
      |> PolicyDeck.pop(3)
      |> PolicyDeck.discard(l, r)

    board = %__MODULE__{board | policy_deck: deck}

    board
    |> play_policy(keep)
    |> shuffle
  end

  defp play_policy(%__MODULE__{liberal_policies_enacted: count} = board, %Policy{team: "liberal"}) do
    %__MODULE__{board | liberal_policies_enacted: count + 1}
  end

  defp play_policy(%__MODULE__{fascist_policies_enacted: count} = board, %Policy{team: "fascist"}) do
    %__MODULE__{board | fascist_policies_enacted: count + 1}
  end
end
