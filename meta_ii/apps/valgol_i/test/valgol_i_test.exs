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
    assert asm.instructions == %{
      0 => {:branch, {:label_ref, "A01"}},
      4 => {:block, 1},
      12 => {:load_literal, 0.0},
      21 => {:store, {:label_ref, "X"}},
      25 => {:load, {:label_ref, "X"}},
      29 => {:load_literal, 3.0},
      38 => :equal,
      39 => {:branch_true, {:label_ref, "A03"}},
      43 => {:load, {:label_ref, "X"}},
      47 => {:load, {:label_ref, "X"}},
      51 => :multiply,
      52 => {:load_literal, 10.0},
      61 => :multiply,
      62 => {:load_literal, 1.0},
      71 => :add,
      72 => {:edit, "01'*'"},
      74 => :print,
      75 => {:load, {:label_ref, "X"}},
      79 => {:load_literal, 0.1},
      88 => :add,
      89 => {:store, {:label_ref, "X"}},
      93 => {:branch, {:label_ref, "A02"}},
      97 => :halt,
      98 => {:space, 1},
      99 => :end,
    }
    assert asm.labels == %{
      "X" => 4,
      "A01" => 12,
      "A02" => 25,
      "A03" => 97,
    }
  end
end
