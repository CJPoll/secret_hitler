defmodule SecretHitlerWeb.GameLive do
  use Phoenix.LiveView
  alias SecretHitlerWeb.GameView
  alias SecretHitler.{Game, Policy}

  @players [
    "Tiffany",
    "Derek",
    "Daniel",
    "Josh",
    "JD",
    "Catalina",
    "Cody"
  ]

  def render(assigns) do
    GameView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    {:ok, assign(socket, :game, Game.new(@players))}
  end

  def handle_event("nominate", player, socket) do
    {:noreply, update(socket, :game, &Game.nominate(&1, player))}
  end

  def handle_event("elect", vote, socket) do
    vote = String.to_existing_atom(vote)

    {:noreply, update(socket, :game, &Game.vote(&1, vote))}
  end

  def handle_event("discard", team, socket) do
    {:noreply, update(socket, :game, &Game.discard(&1, %Policy{team: team}))}
  end

  def handle_event("end-peek", _, socket) do
    {:noreply, update(socket, :game, &Game.end_peek(&1))}
  end

  def handle_event("investigate", player, socket) do
    {:noreply, update(socket, :game, &Game.investigate(&1, player))}
  end

  def handle_event("special-election", player, socket) do
    {:noreply, update(socket, :game, &Game.special_election(&1, player))}
  end

  def handle_event("execute", player, socket) do
    {:noreply, update(socket, :game, &Game.execute(&1, player))}
  end
end
