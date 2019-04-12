defmodule SecretHitlerWeb.BoardLive do
  use Phoenix.LiveView
  alias SecretHitlerWeb.BoardView
  alias SecretHitler.{Board, Policy}

  def render(assigns) do
    BoardView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    {:ok, assign(socket, :board, Board.new())}
  end

  def handle_event("fail-election", _, socket) do
    {:noreply, update(socket, :board, &Board.election_failed(&1))}
  end

  def handle_event("succeed-election", _, socket) do
    {:noreply, update(socket, :board, &Board.election_succeeded(&1))}
  end

  def handle_event("keep-liberal", _, socket) do
    {:noreply,
     update(socket, :board, fn board ->
       %{keep: keep, discards: discards} =
         board
         |> Board.peek(3)
         |> Policy.select("liberal")

       Board.commit(board, discards, keep)
     end)}
  end

  def handle_event("keep-fascist", _, socket) do
    {:noreply,
     update(socket, :board, fn board ->
       %{keep: keep, discards: discards} =
         board
         |> Board.peek(3)
         |> Policy.select("fascist")

       Board.commit(board, discards, keep)
     end)}
  end
end
