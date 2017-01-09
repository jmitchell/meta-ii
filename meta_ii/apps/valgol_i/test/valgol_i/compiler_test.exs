defmodule ValgolI.Compiler.Test do
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
    example_program =
      ValgolI.Machine.example_program |> normalize_assembly

    assert {:ok, compiler_machine} = ValgolI.Compiler.compile(@example_program)
    valgol_assembly =
      compiler_machine[:card] |> normalize_assembly

    assert valgol_assembly == example_program
  end

  def normalize_assembly(asm) do
    asm
    |> String.split("\n")
    |> Enum.map(&String.trim_trailing/1)
    |> Enum.filter(fn(s) -> s != "" end)
    |> Enum.join("\n")
  end
end
