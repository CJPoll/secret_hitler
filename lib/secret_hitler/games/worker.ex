defmodule Undefined do
  defmacro __using__(_) do
    quote do
      def unquote(:"$handle_undefined_function")(function_name, [ref | args]) do
        GenServer.cast(ref, {:rpc, function_name, args})
      end
    end
  end
end

defmodule SecretHitler.Games.Worker do
  use GenServer
  use Undefined
  alias SecretHitler.Session

  def ensure_exists(game_name, host_id) do
    case start_link(game_name) do
      {:ok, pid} ->
        set_owner(pid, host_id)
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}
    end
  end

  def monitor(pid) do
    Process.monitor(pid)
  end

  def owner(pid) do
    GenServer.call(pid, :owner)
  end

  def set_owner(pid, host_id) do
    GenServer.call(pid, {:owner, host_id})
  end

  def spec(game_name) do
    %{id: game_name, start: {__MODULE__, :start_link, [game_name]}}
  end

  def start() do
    GenServer.start(__MODULE__, [])
  end

  def start(game_name) do
    GenServer.start(__MODULE__, [], name: String.to_atom(game_name))
  end

  def start_link(game_name) do
    GenServer.start_link(__MODULE__, [], name: String.to_atom(game_name))
  end

  def stop(ref) do
    GenServer.stop(ref)
  end

  def join(ref, name, host_id) do
    GenServer.call(ref, {:join, name, host_id})
  end

  def kick(ref, player) do
    GenServer.cast(ref, {:kick, player})
  end

  def move_up(ref, player) do
    GenServer.cast(ref, {:move_up, player})
  end

  def move_down(ref, player) do
    GenServer.cast(ref, {:move_down, player})
  end

  def player_for_host(ref, host_id) do
    GenServer.call(ref, {:player_name, host_id})
  end

  def players(ref) do
    GenServer.call(ref, :players)
  end

  def observe(ref, pid) do
    GenServer.cast(ref, {:observe, pid})
  end

  def observers(ref) do
    GenServer.call(ref, :observers)
  end

  def start_game(ref) do
    GenServer.cast(ref, :start_game)
  end

  # Callback Functions

  def game(ref) do
    GenServer.call(ref, :game)
  end

  def init(_args) do
    :timer.send_after(:timer.hours(2), :shutdown)
    {:ok, Session.new()}
  end

  def handle_call(
        {:join, player, host_id},
        _from,
        %Session{} = old_session
      ) do
    new_session = Session.add_player(old_session, player, host_id)

    notify_on_update(old_session, new_session)

    {:reply, :ok, new_session}
  end

  def handle_call(:start, _from, %Session{} = session) do
    session = Session.start(session)
    {:reply, :ok, session}
  end

  def handle_call(:game, _from, %Session{game: game} = session) do
    {:reply, game, session}
  end

  def handle_call(:observers, _from, %Session{observers: observers} = session) do
    {:reply, observers, session}
  end

  def handle_call(:owner, _from, %Session{} = session) do
    owner = Session.owner(session)
    {:reply, owner, session}
  end

  def handle_call({:owner, host_id}, _from, %Session{} = session) do
    session = Session.owner(session, host_id)
    {:reply, :ok, session}
  end

  def handle_call(:players, _from, %Session{} = session) do
    {:reply, Session.players(session), session}
  end

  def handle_call({:player_name, host_id}, _from, %Session{} = session) do
    {:reply, Session.player_name(session, host_id), session}
  end

  def handle_cast({:kick, player}, %Session{} = old_session) do
    new_session = Session.kick(old_session, player)

    notify_on_update(old_session, new_session)

    {:noreply, new_session}
  end

  def handle_cast({:move_up, player}, %Session{} = old_session) do
    new_session = Session.move_up(old_session, player)
    notify_on_update(old_session, new_session)

    {:noreply, new_session}
  end

  def handle_cast({:move_down, player}, %Session{} = old_session) do
    new_session = Session.move_down(old_session, player)
    notify_on_update(old_session, new_session)

    {:noreply, new_session}
  end

  def handle_cast({:rpc, function_name, args}, %Session{} = old_session) do
    new_session = Session.rpc(old_session, function_name, args)
    notify_on_update(old_session, new_session)
    {:noreply, new_session}
  end

  def handle_cast({:observe, pid}, %Session{} = old_session) do
    Process.monitor(pid)
    new_session = Session.add_observer(old_session, pid)

    notify_on_update(old_session, new_session)

    {:noreply, new_session}
  end

  def handle_cast(:start_game, %Session{} = old_session) do
    new_session = Session.start_game(old_session)
    notify_on_update(old_session, new_session)
    {:noreply, new_session}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, %Session{} = session) do
    session = Session.remove_observer(session, pid)
    {:noreply, session}
  end

  def handle_info(:shutdown, %Session{} = session) do
    {:stop, :normal, session}
  end

  def handle_info(msg, session) do
    IO.inspect("Unexpected message: #{inspect(msg)}", label: "#{__MODULE__}")
    {:noreply, session}
  end

  defp notify_on_update(session, session), do: :ok

  defp notify_on_update(_old_session, new_session) do
    IO.inspect(new_session, label: "Session")
    Enum.each(new_session.observers, &notify(&1, new_session.game))
  end

  defp notify(observer, game) do
    send(observer, {:game_updated, game})
  end
end
