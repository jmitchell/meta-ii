defmodule ValgolI.Compiler do
  # TODO: Create a new META II project which implements the META II
  # compiler by hand. Use it here so the META II source for the VALGOL
  # I compiler (Figure 1) is sufficient.

  # TODO: Move `compiler` and `compile` into the META II compiler
  # project and make the local `meta_ii_impl` a callback
  def compile(input) do
    meta_ii_impl
    |> MetaII.Compiler.compile
    |> MetaII.Machine.interpret(input)
  end

  def meta_ii_impl do
    """
    .SYNTAX PROGRAM

    PRIMARY = .ID .OUT('LD ' *) /
         .NUMBER .OUT('LDL' *) /
         '(' EXP ')' .,

    TERM = PRIMARY $('*' PRIMARY .OUT('MLT') ) .,

    EXP1 = TERM $('+' TERM .OUT('ADD') /
         '-' TERM .OUT('SUB') ) .,

    EXP = EXP1 ( '.=' EXP1 .OUT('EQU') / .EMPTY) .,

    ASSIGNST = EXP '=' .ID .OUT('ST ' *) .,

    UNTILST = '.UNTIL' .LABEL *1 EXP '.DO' .OUT('BTP' *2)
         ST .OUT('B  ' *1) .LABEL *2 .,

    CONDITIONALST = '.IF' EXP '.THEN' .OUT('BFP' *1)
         ST '.ELSE' .OUT('B  ' *2) .LABEL *1
         ST .LABEL *2 .,

    IOST = 'EDIT' '(' EXP ',' .STRING
         .OUT('EDT' *) ')' /
         'PRINT' .OUT('PNT') .,

    IDSEQ1 = .ID .LABEL * .OUT('BLK 1') .,

    IDSEQ = IDSEQ1 $(',' IDSEQ1) .,

    DEC = '.REAL' .OUT('B  ' *1) IDSEQ .LABEL *1 .,

    BLOCK = '.BEGIN' (DEC '.,' / .EMPTY)
         ST $('.,' ST) '.END' .,

    ST = IOST / ASSIGNST / UNTILST /
         CONDITIONALST / BLOCK .,

    PROGRAM = BLOCK .OUT('HLT')
         .OUT('SP  1') .OUT('END') .,

    .END 
    """
  end
end
