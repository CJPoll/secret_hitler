defmodule SecretHitler.PubSub do
  alias Phoenix.PubSub

  def publish(channel, msg) do
    PubSub.broadcast(__MODULE__, channel, msg)
  end

  def subscribe(channel) do
    PubSub.subscribe(__MODULE__, channel)
  end

  def subscribe(channel, pid) do
    PubSub.subscribe(__MODULE__, pid, channel)
  end
end
