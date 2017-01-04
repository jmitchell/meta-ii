defmodule MetaII.Compiler do
  def meta_ii_impl do
    """
    .SYNTAX PROGRAM

    OUT1 = '*1' .OUT('GN1') / '*2' .OUT('GN2') /
    '*' .OUT('CI') / .STRING .OUT('CL ' *).,

    OUTPUT = ('.OUT' '('
    $ OUT1 ')' / '.LABEL' .OUT('LB') OUT1) .OUT('OUT') .,

    EX3 = .ID .OUT ('CLL' *) / .STRING
    .OUT('TST' *) / '.ID' .OUT('ID') /
    '.NUMBER' .OUT('NUM') /
    '.STRING' .OUT('SR') / '(' EX1 ')' /
    '.EMPTY' .OUT('SET') /
    '$' .LABEL *1 EX3
    .OUT ('BT ' *1) .OUT('SET').,

    EX2 = (EX3 .OUT('BF ' *1) / OUTPUT)
    $(EX3 .OUT('BE') / OUTPUT)
    .LABEL *1 .,

    ST = .ID .LABEL * '=' EX1
    '.,' .OUT('R').,

    PROGRAM = '.SYNTAX' .ID .OUT('ADR' *)
    $ ST '.END' .OUT('END').,

    .END
    """
  end
end
