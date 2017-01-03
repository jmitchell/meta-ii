defmodule ValgolIMachineTest do
  use ExUnit.Case
  doctest ValgolI.Machine

  alias ValgolI.Machine

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
    0 => {:branch, 12},
    4 => {:block, 1},
    12 => {:load_literal, 0.0},
    21 => {:store, 4},
    25 => {:load, 4},
    29 => {:load_literal, 3.0},
    38 => :equal,
    39 => {:branch_true, 97},
    43 => {:load, 4},
    47 => {:load, 4},
    51 => :multiply,
    52 => {:load_literal, 10.0},
    61 => :multiply,
    62 => {:load_literal, 1.0},
    71 => :add,
    72 => {:edit, "*"},
    74 => :print,
    75 => {:load, 4},
    79 => {:load_literal, 0.1},
    88 => :add,
    89 => {:store, 4},
    93 => {:branch, 25},
    97 => :halt,
    98 => {:space, 1},
    99 => :end,
  }

  @program_output """
   *
   *
   *
    *
     *
      *
       *
        *
         *
           *
             *
               *
                 *
                    *
                       *
                          *
                             *
                                *
                                   *
                                       *
                                           *
                                               *
                                                   *
                                                        *
                                                             *
                                                                  *
                                                                       *
                                                                            *
                                                                                 *
                                                                                       *
  """

  test "parse example program" do
    asm = @example_program |> Machine.parse
    assert asm == @parsed_program
  end

  test "interpret example program" do
    state = @parsed_program |> Machine.interpret
    assert state[:output] == @program_output
  end
end
