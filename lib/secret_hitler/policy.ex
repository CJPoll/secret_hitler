defmodule SecretHitler.Policy do
  defstruct [:team]

  @typedoc """
  `team` can be one of 2 values:
    - "liberal"
    - "fascist"
  """
  @type t :: %__MODULE__{team: String.t()}

  @allowed_teams ["liberal", "fascist"]

  def liberal do
    %__MODULE__{team: "liberal"}
  end

  def fascist do
    %__MODULE__{team: "fascist"}
  end

  def liberal?(%__MODULE__{team: "liberal"}), do: true
  def liberal?(%__MODULE__{team: "fascist"}), do: false

  def fascist(%__MODULE__{team: "fascist"}), do: true
  def fascist(%__MODULE__{team: "liberal"}), do: false

  def select(policies, team) when is_list(policies) and team in @allowed_teams do
    Enum.reduce(policies, %{keep: nil, discards: []}, fn
      policy, %{keep: %__MODULE__{}} = acc ->
        Map.update(acc, :discards, [policy], &[policy | &1])

      %__MODULE__{team: ^team} = policy, %{keep: nil} = acc ->
        %{acc | keep: policy}

      policy, acc ->
        Map.update(acc, :discards, [policy], &[policy | &1])
    end)
  end
end
