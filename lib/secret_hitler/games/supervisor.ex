defmodule SecretHitler.Games.Supervisor do
  use DynamicSupervisor

  alias SecretHitler.Games.Worker

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(name) do
    DynamicSupervisor.start_child(__MODULE__, Worker.spec(name))
  end
end
