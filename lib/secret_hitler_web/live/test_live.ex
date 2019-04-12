defmodule SecretHitlerWeb.TestLive do
  use Phoenix.LiveView
  alias SecretHitlerWeb.TestView

  def render(assigns) do
    TestView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    {:ok, assign(socket, :val, 0)}
  end

  def handle_event("inc", _, socket) do
    {:noreply, update(socket, :val, &(&1 + 1))}
  end

  def handle_event("dec", _, socket) do
    {:noreply, update(socket, :val, &(&1 - 1))}
  end
end
