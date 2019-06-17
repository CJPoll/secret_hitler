defmodule SecretHitler.Games.Agent do
  use Agent

  alias SecretHitler.{Policy, PubSub, Session}

  def discard(ref, %Policy{} = policy) do
    Agent.update(ref, game_function(:discard, [policy]))
  end

  def end_peek(ref) do
    Agent.update(ref, game_function(:end_peek, []))
  end

  def ensure_exists(game_name, host_id) do
    case start(game_name) do
      {:ok, pid} ->
        owner(pid, host_id)
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}
    end
  end

  def execute(ref, player) do
    Agent.update(ref, game_function(:execute, [player]))
  end

  def game(ref) do
    Agent.get(ref, fn session -> session.game end)
  end

  def investigate(ref, player) do
    Agent.update(ref, game_function(:investigate, [player]))
  end

  def join(ref, player_name, host_id) do
    Agent.update(ref, fn old_session ->
      new_session = Session.add_player(old_session, player_name, host_id)
      notify_on_update(old_session, new_session)
      new_session
    end)
  end

  def kick(ref, player) do
    Agent.update(ref, fn old_session ->
      new_session = Session.kick(old_session, player)
      notify_on_update(old_session, new_session)
      new_session
    end)
  end

  def monitor(pid) do
    Process.monitor(pid)
  end

  def move_up(ref, player) do
    Agent.update(ref, fn old_session ->
      new_session = Session.move_up(old_session, player)
      notify_on_update(old_session, new_session)
      new_session
    end)
  end

  def move_down(ref, player) do
    Agent.update(ref, fn old_session ->
      new_session = Session.move_down(old_session, player)
      notify_on_update(old_session, new_session)
      new_session
    end)
  end

  def nominate(ref, player) do
    Agent.update(ref, game_function(:nominate, [player]))
  end

  def observe(game_name, pid) do
    PubSub.subscribe(game_name, pid)

    game_name
    |> String.to_atom()
    |> Process.whereis()
    |> Agent.update(fn session ->
      notify(session)
      session
    end)
  end

  def observers(ref) do
    Agent.get(ref, fn session -> session.observers end)
  end

  def owner(ref) do
    Agent.get(ref, &Session.owner/1)
  end

  def owner(ref, host_id) do
    Agent.update(ref, fn session -> Session.owner(session, host_id) end)
  end

  def player_for_host(ref, host_id) do
    Agent.get(ref, fn session -> Session.player_name(session, host_id) end)
  end

  def players(ref) do
    Agent.get(ref, &Session.players/1)
  end

  def spec(game_name) do
    %{id: game_name, start: {__MODULE__, :start_link, [game_name]}}
  end

  def special_election(ref, player) do
    Agent.update(ref, game_function(:special_election, [player]))
  end

  def start(game_name) do
    Agent.start(fn -> do_start(game_name) end, name: String.to_atom(game_name))
  end

  def start_game(ref) do
    Agent.update(ref, fn old_session ->
      new_session = Session.start_game(old_session)
      notify_on_update(old_session, new_session)
      new_session
    end)
  end

  def start_link(game_name) do
    Agent.start_link(fn -> do_start(game_name) end, name: String.to_atom(game_name))
  end

  def stop(ref) do
    Agent.stop(ref)
  end

  def vote(ref, player, vote) do
    Agent.update(ref, game_function(:vote, [player, vote]))
  end

  # Private Functions

  defp do_start(game_name) do
    :timer.send_after(:timer.hours(2), :shutdown)
    Session.new(game_name)
  end

  defp game_function(name, args) do
    fn old_session ->
      new_session = Session.game_function(old_session, name, args)
      notify_on_update(old_session, new_session)
      new_session
    end
  end

  defp notify_on_update(session, session), do: :ok

  defp notify_on_update(_old_session, new_session) do
    IO.inspect(new_session, label: "Session")
    notify(new_session)
  end

  defp notify(session) do
    PubSub.publish(session.name, {:game_updated, session.game})
  end
end
