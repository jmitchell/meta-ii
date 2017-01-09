defmodule ValgolICompilerTest do
  use ExUnit.Case
  doctest ValgolI.Compiler

  alias ValgolI.Compiler

  @example_program """
  .BEGIN
  .REAL X ., 0 = X .,
  .UNTIL X .= 3 .DO .BEGIN
       EDIT( X*X * 10 + 1, '*') ., PRINT ., X + 0.1 = X
       .END
  .END
  """

  test "compile example program" do
    IO.puts "Compiled VALGOL I program: #{inspect ValgolI.Compiler.compile(@example_program)}"
  end
end
