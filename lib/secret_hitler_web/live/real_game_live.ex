defmodule SecretHitlerWeb.RealGameLive do
  use Phoenix.LiveView
  alias SecretHitlerWeb.GameView
  alias SecretHitler.Policy

  @process_module SecretHitler.Games.Agent

  def render(assigns) do
    GameView.render("index.html", assigns)
  end

  def mount(%{game_name: game_name, host_id: host_id}, socket) do
    {:ok, pid} = @process_module.ensure_exists(game_name, host_id)

    @process_module.monitor(pid)
    @process_module.observe(game_name, self())

    owner = @process_module.owner(pid)
    game = @process_module.game(pid) |> IO.inspect(label: "initial game")
    current_player = @process_module.player_for_host(pid, host_id)
    players = @process_module.players(pid)

    socket =
      socket
      |> assign(:current_player, current_player)
      |> assign(:game, game)
      |> assign(:host_id, host_id)
      |> assign(:owner, owner)
      |> assign(:pid, pid)
      |> assign(:players, players)
      |> assign(:spectator, game != nil and current_player == nil)
      |> assign(:show_info, false)
      |> assign(:show_knowledge, false)

    {:ok, socket}
  end

  def handle_info({:game_updated, game}, socket) do
    IO.inspect(game, label: "Game updated")
    players = @process_module.players(socket.assigns.pid)
    owner = @process_module.owner(socket.assigns.pid)

    current_player =
      @process_module.player_for_host(socket.assigns.pid, socket.assigns.host_id)
      |> IO.inspect(label: "Current Player")

    socket =
      socket
      |> update(:current_player, fn _ -> current_player end)
      |> update(:game, fn _ -> game end)
      |> update(:players, fn _ -> players end)
      |> update(:owner, fn _ -> owner end)

    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    IO.inspect("Unexpected message: #{inspect(msg)}", label: "#{__MODULE__}")
    {:noreply, socket}
  end

  def handle_event("join", %{"player" => %{"name" => name}}, socket) do
    pid = socket.assigns.pid
    host_id = socket.assigns.host_id
    @process_module.join(pid, name, host_id)
    {:noreply, assign(socket, :current_player, name)}
  end

  def handle_event("nominate", player, socket) do
    @process_module.nominate(socket.assigns.pid, player)
    {:noreply, socket}
  end

  def handle_event("vote", vote, socket) do
    @process_module.vote(socket.assigns.pid, socket.assigns.current_player, vote)
    {:noreply, socket}
  end

  def handle_event("discard", team, socket) do
    @process_module.discard(socket.assigns.pid, %Policy{team: team})
    {:noreply, socket}
  end

  def handle_event("end-peek", _, socket) do
    @process_module.end_peek(socket.assigns.pid)
    {:noreply, socket}
  end

  def handle_event("investigate", player, socket) do
    @process_module.investigate(socket.assigns.pid, player)
    {:noreply, socket}
  end

  def handle_event("special-election", player, socket) do
    @process_module.special_election(socket.assigns.pid, player)
    {:noreply, socket}
  end

  def handle_event("execute", player, socket) do
    @process_module.execute(socket.assigns.pid, player)
    {:noreply, socket}
  end

  def handle_event("start-game", _, socket) do
    @process_module.start_game(socket.assigns.pid)
    {:noreply, socket}
  end

  def handle_event("toggle-info", _, socket) do
    {:noreply, update(socket, :show_info, &(not &1))}
  end

  def handle_event("toggle-knowledge", _, socket) do
    {:noreply, update(socket, :show_knowledge, &(not &1))}
  end

  def handle_event("kick", player, socket) do
    @process_module.kick(socket.assigns.pid, player)
    {:noreply, socket}
  end

  def handle_event("move-up", player, socket) do
    @process_module.move_up(socket.assigns.pid, player)
    {:noreply, socket}
  end

  def handle_event("move-down", player, socket) do
    @process_module.move_down(socket.assigns.pid, player)
    {:noreply, socket}
  end
end
