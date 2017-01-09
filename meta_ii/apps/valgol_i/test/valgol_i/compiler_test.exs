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
    compiler_machine = ValgolI.Compiler.compile(@example_program)
    IO.puts "VALGOL I Compiler as a META II machine:\n#{inspect compiler_machine, pretty: true}"
    refute {:error, _} = compiler_machine
  end
end
