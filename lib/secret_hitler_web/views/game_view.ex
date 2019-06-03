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

  defp special_election?(game, player) do
    Game.special_election?(game, player)
  end

  defp policy_peek?(game, player) do
    Game.policy_peek?(game, player)
  end

  defp investigate_loyalty?(game, player) do
    Game.investigate_loyalty?(game, player)
  end

  defp execution?(game, player) do
    Game.execution?(game, player)
  end

  defp fascist_count(game) do
    length(game.fascists)
  end

  defp liberal_count(game) do
    length(game.players) - length(game.fascists)
  end

  defp team_color("liberal"), do: :blue
  defp team_color("fascist"), do: :red

  defp button(:red, click, value, text) do
    button("btn btn-danger", click, value, text)
  end

  defp button(:blue, click, value, text) do
    button("btn btn-primary", click, value, text)
  end

  defp button(class, click, value, text) do
    if value do
      raw(
        "<button class=\"#{class}\" phx-click=\"#{click}\" phx-value=\"#{value}\">#{text}</button>"
      )
    else
      raw("<button class=\"#{class}\" phx-click=\"#{click}\">#{text}</button>")
    end
  end
end
