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

  @parsed_program %{
    address: 100,
    instructions: %{
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
    },
    labels: %{
      "X" => 4,
      "A01" => 12,
      "A02" => 25,
      "A03" => 97,
    }
  }

  @label_derefed_program %{
    address: 100,
    instructions: %{
      0 => {:branch, {:address, 12}},
      4 => {:block, 1},
      12 => {:load_literal, 0.0},
      21 => {:store, {:address, 4}},
      25 => {:load, {:address, 4}},
      29 => {:load_literal, 3.0},
      38 => :equal,
      39 => {:branch_true, {:address, 97}},
      43 => {:load, {:address, 4}},
      47 => {:load, {:address, 4}},
      51 => :multiply,
      52 => {:load_literal, 10.0},
      61 => :multiply,
      62 => {:load_literal, 1.0},
      71 => :add,
      72 => {:edit, "01'*'"},
      74 => :print,
      75 => {:load, {:address, 4}},
      79 => {:load_literal, 0.1},
      88 => :add,
      89 => {:store, {:address, 4}},
      93 => {:branch, {:address, 25}},
      97 => :halt,
      98 => {:space, 1},
      99 => :end,
    },
    labels: %{
      "X" => 4,
      "A01" => 12,
      "A02" => 25,
      "A03" => 97,
    }
  }


  test "parse example program" do
    asm = @example_program |> ValgolI.parse
    assert asm == @parsed_program
  end

  test "dereference labels in parsed assembly" do
    asm = @parsed_program |> ValgolI.dereference_labels
    assert asm == @label_derefed_program
  end
end
