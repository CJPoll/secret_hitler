defmodule SecretHitlerWeb.GameView do
  def select_player(players, assigns, click_value, action) do
    render(
      "_select_player.html",
      assigns
      |> assign_value(:players, players)
      |> assign_value(:click_value, click_value)
      |> assign_value(:action, action)
    )
  end

  use SecretHitlerWeb, :view
  alias SecretHitler.{Board, Game}

  defp assign_value(assigns, key, value) do
    Map.update(assigns, key, value, fn _ -> value end)
  end

  defp game_started?(nil), do: false
  defp game_started?(%Game{}), do: true

  defp registered?(nil), do: false
  defp registered?(name) when is_binary(name), do: true

  defp discarding?(game, player) do
    Game.discarding?(game, player)
  end

  defp nominating_chancellor?(game, player) do
    Game.nominating_chancellor?(game, player)
  end

  defp voting?(game, player) do
    Game.voting?(game, player)
  end

  defp team_class("fascist"), do: "btn-danger"
  defp team_class("liberal"), do: "btn-primary"

  defp special_election?(game, player) do
    Game.special_election?(game, player)
  end

  defp policy_peek?(game, player) do
    Game.policy_peek?(game, player)
  end

  defp execution?(game, player) do
    Game.execution?(game, player)
  end
end
