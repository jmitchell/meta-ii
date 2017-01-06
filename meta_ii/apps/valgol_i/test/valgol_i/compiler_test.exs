defmodule ValgolI.Compiler.Test do
  use ExUnit.Case
  doctest ValgolI.Compiler

  alias ValgolI.Compiler

  def example_program do
  """
  .BEGIN
  .REAL X ., 0 = X .,
  .UNTIL X .= 3 .DO .BEGIN
       EDIT( X*X * 10 + 1, '*') ., PRINT ., X + 0.1 = X
       .END
  .END
  """
  end

  @tag :skip
  test "compile example program" do
    assert Compiler.compile(example_program) == ValgolIMachineTest.example_program
  end
end
