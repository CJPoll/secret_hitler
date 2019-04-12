defmodule SecretHitler.PolicyDeck do
  use Schemata

  alias SecretHitler.Policy

  defstruct [:draw_policies, :discard_policies]

  def starting_deck do
    :rand.seed(:exsplus, {time_seed(), time_seed(), time_seed()})
    liberals = for _n <- 1..6, do: Policy.liberal()

    fascists = for _n <- 1..11, do: Policy.fascist()

    policies = (liberals ++ fascists) |> Enum.shuffle()

    %__MODULE__{
      draw_policies: policies,
      discard_policies: []
    }
  end

  def draw_pile_size(%__MODULE__{draw_policies: cards}), do: Enum.count(cards)
  def discard_pile_size(%__MODULE__{discard_policies: cards}), do: Enum.count(cards)

  def peek(%__MODULE__{draw_policies: deck}, count) do
    Enum.take(deck, count)
  end

  def pop(%__MODULE__{draw_policies: deck} = decks, count) do
    deck = Enum.drop(deck, count)
    %__MODULE__{decks | draw_policies: deck}
  end

  def discard(%__MODULE__{discard_policies: discard} = deck, l, r) do
    %__MODULE__{deck | discard_policies: [l, r | discard]}
  end

  def time_seed do
    seed = DateTime.utc_now() |> DateTime.to_unix()

    seed - :rand.uniform(10000)
  end

  def shuffle(%__MODULE__{discard_policies: discards, draw_policies: draws} = deck) do
    %__MODULE__{deck | discard_policies: [], draw_policies: discards ++ draws}
  end
end
