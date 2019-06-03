defmodule SecretHitler.Events.Discard do
  defstruct [:team, :index]
end

defimpl SecretHitler.Event, for: SecretHitler.Events.Discard do
  alias SecretHitler.{Game, Events.Discard}

  def apply(%Discard{index: index, team: nil}, %Game{} = game) when is_integer(index) do
    policy =
      game
      |> Game.policy_choices()
      |> Enum.fetch!(index)

    Game.discard(game, policy)
  end

  def apply(%Discard{index: nil, team: team}, %Game{} = game) when is_binary(team) do
    policy =
      game
      |> Game.policy_choices()
      |> Enum.find(fn policy -> policy.team == team end)

    case policy do
      nil ->
        raise "Invalid event - chose team that was not an option"

      policy ->
        Game.discard(game, policy)
    end
  end
end
