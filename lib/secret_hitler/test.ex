defmodule Test do
  def recurse([]) do
    :ok
  end

  def recurse([%{"hello" => {:ok, something}} = e | rest]) do
    a = {:ok, "some result"}

    {:ok, result} = a

    IO.inspect(something)
    recurse(rest)
  end

  def recurse([e | rest]) do
    IO.inspect(e)
    recurse(rest)
  end
end
