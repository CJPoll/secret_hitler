defmodule SecretHitler.Queue do
  defstruct [:queue]

  @opaque t :: %__MODULE__{}

  def new() do
    %__MODULE__{queue: :queue.new()}
  end

  def new(elements) when is_list(elements) do
    if Enum.any?(elements, &is_nil/1) do
      raise "Queue does not allow `nil` values"
    end

    %__MODULE__{queue: :queue.from_list(elements)}
  end

  def push(%__MODULE__{queue: queue}, item) when not is_nil(item) do
    queue = :queue.in(item, queue)
    %__MODULE__{queue: queue}
  end

  def peek(%__MODULE__{queue: queue}) do
    case :queue.peek(queue) do
      :empty -> nil
      {:value, item} -> item
    end
  end

  @spec pop(t) :: {t, term}
  def pop(%__MODULE__{queue: queue} = q) do
    case :queue.out(queue) do
      {:empty, _} ->
        {q, nil}

      {{:value, item}, queue} ->
        {%__MODULE__{queue: queue}, item}
    end
  end

  def rotate(%__MODULE__{} = q) do
    {q, item} = pop(q)
    push(q, item)
  end

  def drop(%__MODULE__{queue: queue}, item) do
    q = :queue.to_list(queue)

    elements = q -- [item]

    new(elements)
  end
end
