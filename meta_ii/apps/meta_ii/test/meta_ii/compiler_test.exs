defmodule MetaII.Compiler.Test do
  use ExUnit.Case, async: true
  doctest MetaII.Compiler

  # alias MetaII.Compiler

  # describe "Compiler.compile/1" do
  #   @tag :skip			# TODO
  #   test "translate META II program into META II machine code" do
  #     Compiler.meta_ii_impl
  #     |> Compiler.compile
  #     |> assert_match(
  # 	{:ok,
  # 	 %{
  # 	   src: %{
  # 	     # .SYNTAX PROGRAM
  # 	     1 => "",

  # 	     # OUT1 = '*1' .OUT('GN1') / '*2' .OUT('GN2') /
  # 	     # '*' .OUT('CI') / .STRING .OUT('CL ' *).,
  # 	     3 => "",

  # 	     # OUTPUT = ('.OUT' '('
  # 	     # $ OUT1 ')' / '.LABEL' .OUT('LB') OUT1) .OUT('OUT') .,
  # 	     6 => "",

  # 	     # EX3 = .ID .OUT ('CLL' *) / .STRING
  # 	     # .OUT('TST' *) / '.ID' .OUT('ID') /
  # 	     # '.NUMBER' .OUT('NUM') /
  # 	     # '.STRING' .OUT('SR') / '(' EX1 ')' /
  # 	     # '.EMPTY' .OUT('SET') /
  # 	     # '$' .LABEL *1 EX3
  # 	     # .OUT ('BT ' *1) .OUT('SET').,
  # 	     9 => "",

  # 	     # EX2 = (EX3 .OUT('BF ' *1) / OUTPUT)
  # 	     # $(EX3 .OUT('BE') / OUTPUT)
  # 	     # .LABEL *1 .,
  # 	     17 => "",

  # 	     # EX1 = EX2 $('/' .OUT('BT ' *1) EX2 )
  # 	     # .LABEL *1 .,
  # 	     21 => "",

  # 	     # ST = .ID .LABEL * '=' EX1
  # 	     # '.,' .OUT('R').,
  # 	     24 => "",

  # 	     # PROGRAM = '.SYNTAX' .ID .OUT('ADR' *)
  # 	     # $ ST '.END' .OUT('END').,
  # 	     27 => "",

  # 	     # .END
  # 	     30 => "",
  # 	   }
  # 	 }
  # 	}
  #     )
  #   end
  # end
end
