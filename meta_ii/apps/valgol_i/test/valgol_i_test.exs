defmodule ValgolITest do
  use ExUnit.Case
  doctest ValgolI

  @example_program """
         B   A01
  X
         BLK 001
  A01
         LDL 0
         ST  X
  A02
         LD  X
         LDL 3
         EQU
         BTP A03
         LD  X
         LD  X
         MLT
         LDL 10
         MLT
         LDL 1
         ADD
         EDT 01'*'
         PNT
         LD  X
         LDL 0.1
         ADD
         ST  X
         B   A02
  A03
         HLT
         SP  1
         END
  """

  test "parse example program" do
    asm = @example_program |> ValgolI.parse
    assert asm.instructions == [
      {:branch, {:label_ref, "A01"}},
      {:block, 1},
      {:load_literal, 0.0},
      {:store, {:label_ref, "X"}},
      {:load, {:label_ref, "X"}},
      {:load_literal, 3.0},
      :equal,
      {:branch_true, {:label_ref, "A03"}},
      {:load, {:label_ref, "X"}},
      {:load, {:label_ref, "X"}},
      :multiply,
      {:load_literal, 10.0},
      :multiply,
      {:load_literal, 1.0},
      :add,
      {:edit, "01'*'"},
      :print,
      {:load, {:label_ref, "X"}},
      {:load_literal, 0.1},
      :add,
      {:store, {:label_ref, "X"}},
      {:branch, {:label_ref, "A02"}},
      :halt,
      {:space, 1},
      :end,
    ]
    assert asm.labels == %{
      "X" => 4,
      "A01" => 12,
      "A02" => 25,
      "A03" => 97,
    }
  end
end
