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

  defmodule State do
    alias SecretHitler.{Game, GameSetup}
    defstruct [:game, :owner, game_setup: GameSetup.new(), observers: MapSet.new(), hosts: %{}]

    def add_observer(%__MODULE__{} = state, pid) do
      observers = MapSet.put(state.observers, pid)
      %__MODULE__{state | observers: observers}
    end

    def game_started?(%__MODULE__{game: nil}), do: false
    def game_started?(%__MODULE__{game: %Game{}}), do: true

    def player_name(%__MODULE__{hosts: hosts}, host_id) do
      hosts[host_id]
    end

    def add_player_name(%__MODULE__{game: nil, hosts: hosts} = state, host_id, player) do
      hosts = Map.update(hosts, host_id, player, fn _ -> player end)
      %__MODULE__{state | hosts: hosts}
    end

    def owner(%__MODULE__{owner: owner} = state) do
      player_name(state, owner)
    end

    def players(%__MODULE__{game: nil, hosts: hosts}) do
      Map.values(hosts)
    end

    def players(%__MODULE__{game: game}) do
      game.players
    end

    def remove_observer(%__MODULE__{} = state, pid) do
      observers = MapSet.delete(state.observers, pid)
      %__MODULE__{state | observers: observers}
    end

    def rpc(%__MODULE__{game: %Game{} = game} = state, function, args) do
      game = apply(Game, function, [game | args])
      %__MODULE__{state | game: game}
    end

    def start_game(%__MODULE__{} = state) do
      game = GameSetup.to_game(state.game_setup)
      %__MODULE__{state | game: game}
    end
  end

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

  alias SecretHitler.{GameSetup, Game}

  def start() do
    GenServer.start(__MODULE__, [])
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
    {:ok, %State{}}
  end

  def handle_call(
        {:join, player, host_id},
        _from,
        %State{game: nil, game_setup: setup} = old_state
      ) do
    new_state = %State{old_state | game_setup: GameSetup.add_player(setup, player)}
    new_state = State.add_player_name(new_state, host_id, player)

    notify_on_update(old_state, new_state)

    {:reply, :ok, new_state}
  end

  def handle_call(:start, _from, %State{game: nil, game_setup: setup} = state) do
    state = %State{state | game_setup: GameSetup.to_game(setup)}
    {:reply, :ok, state}
  end

  def handle_call(:game, _from, %State{game: game} = state) do
    {:reply, game, state}
  end

  def handle_call(:observers, _from, %State{observers: observers} = state) do
    {:reply, observers, state}
  end

  def handle_call(:owner, _from, %State{} = state) do
    owner = State.owner(state)
    {:reply, owner, state}
  end

  def handle_call({:owner, host_id}, _from, %State{} = state) do
    state = %State{state | owner: host_id}
    {:reply, :ok, state}
  end

  def handle_call(:players, _from, %State{} = state) do
    {:reply, State.players(state), state}
  end

  def handle_call({:player_name, host_id}, _from, %State{} = state) do
    {:reply, State.player_name(state, host_id), state}
  end

  def handle_cast({:rpc, function_name, args}, %State{} = old_state) do
    new_state = State.rpc(old_state, function_name, args)
    notify_on_update(old_state, new_state)
    {:noreply, new_state}
  end

  def handle_cast({:observe, pid}, %State{} = old_state) do
    Process.monitor(pid)
    new_state = State.add_observer(old_state, pid)

    notify_on_update(old_state, new_state)

    {:noreply, new_state}
  end

  def handle_cast(:start_game, %State{} = old_state) do
    new_state = State.start_game(old_state)
    notify_on_update(old_state, new_state)
    {:noreply, new_state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, %State{} = state) do
    state = State.remove_observer(state, pid)
    {:noreply, state}
  end

  def handle_info(:shutdown, %State{} = state) do
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    IO.inspect("Unexpected message: #{inspect(msg)}", label: "#{__MODULE__}")
    {:noreply, state}
  end

  defp notify_on_update(state, state), do: :ok

  defp notify_on_update(_old_state, new_state) do
    Enum.each(new_state.observers, &notify(&1, new_state.game))
  end

  defp notify(observer, game) do
    send(observer, {:game_updated, game})
  end
end
