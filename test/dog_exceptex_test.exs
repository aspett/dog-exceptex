defmodule DogExceptexTest do
  use ExUnit.Case
  doctest DogExceptex

  test "greets the world" do
    assert DogExceptex.hello() == :world
  end
end
