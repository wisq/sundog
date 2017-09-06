defmodule SundogTest do
  use ExUnit.Case
  doctest Sundog

  test "greets the world" do
    assert Sundog.hello() == :world
  end
end
