defmodule MetaII.Compiler.Test do
  use ExUnit.Case, async: true
  doctest MetaII.Compiler

  alias MetaII.Compiler

  defmacro assert_match(actual, expected) do
    quote do
      assert match?(unquote(expected), unquote(actual))
    end
  end

  describe "Compiler.parse/1" do
    test "parse META II compiler program for VALGOL I" do
      ValgolI.Compiler.meta_ii_impl
      |> Compiler.parse
      |> assert_match(
	{:ok,
	 %{
	   # .SYNTAX PROGRAM
	   1 => {:_syntax, "PROGRAM"},

	   # PRIMARY = .ID .OUT('LD ' *) /
	   #      .NUMBER .OUT('LDL' *) /
	   #      '(' EXP ')' .,
	   3 => {:st, "PRIMARY",
		 {:ex1,
		  {:ex2,
		   # .ID .OUT('LD ' *)
		   {:ex3, :_id},
		   [{:output, :_out,
		     [{:out1, :_string, "LD "},
		      {:out1, :_asterisk}]}]},
		  [{:ex2,
		    # .NUMBER .OUT('LDL' *)
		    {:ex3, :_number,
		     [{:output, :_out,
		       [{:out1, :_string, "LDL"},
			{:out1, :_asterisk}]}]},
		    # '(' EXP ')'
		    [{:ex3, :_paren,
		      {:ex1,
		       {:ex2,
			{:ex3, :_id, "EXP"}}}}]}]}},

	   # TERM = PRIMARY $('*' PRIMARY .OUT('MLT') ) .,
	   7 => {:st, "TERM",
		 {:ex1,
		  {:ex2,
		   # PRIMARY
		   {:ex3, :_id, "PRIMARY"},
		   [ # $
		     {:ex3, :_dollar,
		      # (
		      {:ex3, :_paren,
		       {:ex1,
			{:ex2,
			 # '*'
			 {:ex3, :_string, "*"},
			 [ # PRIMARY
			   {:ex3, :_id, "PRIMARY"},
			   # .OUT('MLT')
			   {:output, :_out,
			    {:out1, :_string, "MLT"}}]}}}}]}}},

	   # EXP1 = TERM $('+' TERM .OUT('ADD') /
	   #      '-' TERM .OUT('SUB') ) .,
	   9 => {:st, "EXP1",
		 {:ex1,
		  {:ex2,
		   # TERM
		   {:ex3, :_id, "TERM"},
		   [ # $
		     {:ex3, :_dollar,
		      # (
		      {:ex3, :_paren,
		       {:ex1,
			{:ex2,
			 # '+'
			 {:ex3, :_string, "+"},
			 [ # TERM
			   {:ex3, :_id, "TERM"},
			   # .OUT('ADD')
			   {:output, :_out,
			    {:out1, :_string, "ADD"}}]},
			[{:ex2,
			  # '-'
			  {:ex3, :_string, "-"},
			  [ # TERM
			    {:ex3, :_id, "TERM"},
			    # .OUT('SUB')
			    {:output, :_out,
			     {:out1, :_string, "SUB"}}]}]}}}]}}},

	   # EXP = EXP1 ( '.*' EXP1 .OUT('EQU') / .EMPTY) .,
	   12 => {:st, "EXP",
		  {:ex1,
		   {:ex2,
		    # EXP1
		    {:ex3, :_id, "EXP1"},
		    [ # (
		      {:ex3, :_paren,
		       {:ex1,
			{:ex2,
			 # '.*'
			 {:ex3, :_string, ".*"},
			 [ # EXP1
			   {:ex3, :_id, "EXP1"},
			   # .OUT('EQU')
			   {:output, :_out,
			    {:out1, :_string, "EQU"}}]},
			[{:ex2,
			  # .EMPTY
			  {:ex3, :_empty}}]}}]}}},

	   # ASSIGNST = EXP '=' .ID .OUT('ST ' *) .,
	   14 => {:st, "ASSIGNST",
		  {:ex1,
		   {:ex2,
		    # EXP
		    {:ex3, :_id, "EXP"},
		    [ # '='
		      {:ex3, :_string, "="},
		      [ # .ID
			{:ex3, :_id},
			[{:output, :_out,
			  [{:out1, :_string, "ST "},
			   {:out1, :_asterisk}]}]]]}}},

	   # UNTILST = '.UNTIL' .LABEL *1 EXP '.DO' .OUT('BTP' *2)
	   #      ST .OUT('B  ' *1) .LABEL *2 .,
	   16 => {:st, "UNTILST",
		  {:ex1,
		   {:ex2,
		    # '.UNTIL'
		    {:ex3, :_string, ".UNTIL"},
		    [ # .LABEL *1
		      {:output, :_label, {:out1, :_gen1}},
		      # EXP
		      {:ex3, :_id, "EXP"},
		      # '.DO'
		      {:ex3, :_string, ".DO"},
		      # .OUT('BTP' *2)
		      {:output, :_out,
		       [{:out1, :_string, "BTP"},
			{:out1, :_gen2}]},
		      # ST
		      {:ex3, :_id, "ST"},
		      # .OUT('B  ' *1)
		      {:output, :_out,
		       [{:out1, :_string, "B  "},
			{:out1, :_gen1}]},
		      # .LABEL *2
		      {:output, :_label, {:out1, :_gen2}}]}}},

	   # CONDITIONALST = '.IF' EXP '.THEN' .OUT('BFP' *1)
	   #      ST '.ELSE' .OUT('B  ' *2) .LABEL *1
	   #      ST .LABEL *2 .,
	   19 => {:st, "CONDITIONALST",
		  {:ex1,
		   {:ex2,
		    {:ex3, :_string, ".IF"},
		    [ {:ex3, :_id, "EXP"},
		      {:ex3, :_string, ".THEN"},
		      {:output, :_out,
		       [{:out1, :_string, "BFP"},
			{:out1, :_gen1}]},
		      {:ex3, :_id, "ST"},
		      {:ex3, :_string, ".ELSE"},
		      {:output, :_out,
		       [{:out1, :_string, "B  "},
			{:out1, :_gen2}]},
		      {:output, :_label, {:out1, :_gen1}},
		      {:ex3, :_id, "ST"},
		      {:output, :_label, {:out1, :_gen2}}]}}},

	   # IOST = 'EDIT' '(' EXP '.' .STRING
	   #      .OUT('EDT' *) ')' /
	   #      '.PRINT' .OUT('PNT') .,
	   23 => {:st, "IOST",
		  {:ex1,
		   {:ex2,
		    # EDIT
		    {:ex3, :_string, "EDIT"},
		    [ # '(' EXP '.' .STRING .OUT('EDT' *) ')'
		      {:ex3, :_string, "("},
		      {:ex3, :_id, "EXP"},
		      {:ex3, :_string, "."},
		      {:ex3, :_string_sr},
		      {:output, :_out,
		       [{:out1, :_string, "EDT"},
			{:out1, :_asterisk}]},
		      {:ex3, :_string, ")"}]},
		   [{:ex2,
		     # '.PRINT'
		     {:ex3, :_string, ".PRINT"},
		     [ # .OUT('PNT')
		       {:output, :_out,
			[{:out1, :_string, "PNT"}]}]}]}},

	   # IDSEQ1 = .ID .LABEL * .OUT('BLK 1') .,
	   27 => {:st, "IDSEQ1",
		  {:ex1,
		   {:ex2,
		    # .ID
		    {:ex3, :_id},
		    [ # .LABEL *
		      {:output, :_label, {:out1, :_asterisk}},
		      # .OUT('BLK 1')
		      {:output, :_out,
		       [{:out1, :_string, "BLK 1"}]}]}}},

	   # IDSEQ = IDSEQ1 $('.' IDSEQ1) .,
	   29 => {:st, "IDSEQ",
		  {:ex1,
		   {:ex2,
		    # IDSEQ1
		    {:ex3, :_id, "IDSEQ1"},
		    [ # $
		      {:ex3, :_dollar,
		       # (
		       {:ex3, :_paren,
			{:ex1,
			 {:ex2,
			  # '.'
			  {:ex3, :_string, "."},
			  [ # IDSEQ1
			    {:ex3, :_id, "IDSEQ1"}]}}}}]}}},

	   # DEC = '.REAL' .OUT('B  ' *1) IDSEQ .LABEL *1 .,
	   31 => {:st, "DEC",
		  {:ex1,
		   {:ex2,
		    # '.REAL'
		    {:ex3, :_string, ".REAL"},
		    [ # .OUT('B  ' *1)
		      {:output, :_out,
		       [{:out1, :_string, "B  "},
			{:out1, :_gen1}]},
		      # IDSEQ
		      {:ex3, :_label, "IDSEQ"},
		      # .LABEL *1
		      {:output, :_label, {:out1, :_gen1}}]}}},

	   # BLOCK = '.BEGIN' (DEC '.,' / .EMPTY)
	   #      ST $('.,' ST) '.END' .,
	   33 => {:st, "BLOCK",
		  {:ex1,
		   {:ex2,
		    # '.BEGIN'
		    {:ex3, :_string, ".BEGIN"},
		    [ # (DEC '.,' / .EMPTY)
		      {:ex3, :_paren,
		       {:ex1,
			{:ex2,
			 # DEC
			 {:ex3, :_label, "DEC"},
			 [ # '.,'
			   {:ex3, :_string, ".,"}]},
			[ # .EMPTY
			  {:ex2, {:ex3, :_empty}}]}},
		      # ST
		      {:ex3, :_label, "ST"},
		      # $
		      {:ex3, :_dollar,
		       # (
		       {:ex3, :_paren,
			{:ex1,
			 {:ex2,
			  # '.,'
			  {:ex3, :_string, ".,"},
			  [ # ST
			    {:ex3, :_label, "ST"}]}}}},
		      # '.END'
		      {:ex3, :_string, ".END"}]}}},

	   # ST = IOST / ASSIGNST / UNTILST /
	   #      CONDITIONALST / BLOCK .,
	   36 => {:st, "ST",
		  {:ex1,
		   {:ex2, {:ex3, :_label, "IOST"}},
		   [{:ex2, {:ex3, :_label, "ASSIGNST"}},
		    {:ex2, {:ex3, :_label, "UNTILST"}},
		    {:ex2, {:ex3, :_label, "CONDITIONALST"}},
		    {:ex2, {:ex3, :_label, "BLOCK"}}]}},

	   # PROGRAM = BLOCK .OUT('HLT')
	   #      .OUT('SP  1') .OUT('END') .,
	   39 => {:st, "PROGRAM",
		  {:ex1,
		   {:ex2,
		    {:ex3, :_label, "BLOCK"},
		    [{:output, :_out, {:out1, :_string, "HLT"}},
		     {:output, :_out, {:out1, :_string, "SP  1"}},
		     {:output, :_out, {:out1, :_string, "END"}}]}}},

	   # .END
	   42 => :_end,
	 }})
    end
  end

  describe "Compiler.compile/1" do
    @tag :skip			# TODO
    test "translate META II program into META II machine code" do
      Compiler.meta_ii_impl
      |> Compiler.compile
      |> assert_match(
	{:ok,
	 %{
	   src: %{
	     # .SYNTAX PROGRAM
	     1 => "",

	     # OUT1 = '*1' .OUT('GN1') / '*2' .OUT('GN2') /
	     # '*' .OUT('CI') / .STRING .OUT('CL ' *).,
	     3 => "",

	     # OUTPUT = ('.OUT' '('
	     # $ OUT1 ')' / '.LABEL' .OUT('LB') OUT1) .OUT('OUT') .,
	     6 => "",

	     # EX3 = .ID .OUT ('CLL' *) / .STRING
	     # .OUT('TST' *) / '.ID' .OUT('ID') /
	     # '.NUMBER' .OUT('NUM') /
	     # '.STRING' .OUT('SR') / '(' EX1 ')' /
	     # '.EMPTY' .OUT('SET') /
	     # '$' .LABEL *1 EX3
	     # .OUT ('BT ' *1) .OUT('SET').,
	     9 => "",

	     # EX2 = (EX3 .OUT('BF ' *1) / OUTPUT)
	     # $(EX3 .OUT('BE') / OUTPUT)
	     # .LABEL *1 .,
	     17 => "",

	     # EX1 = EX2 $('/' .OUT('BT ' *1) EX2 )
	     # .LABEL *1 .,
	     21 => "",

	     # ST = .ID .LABEL * '=' EX1
	     # '.,' .OUT('R').,
	     24 => "",

	     # PROGRAM = '.SYNTAX' .ID .OUT('ADR' *)
	     # $ ST '.END' .OUT('END').,
	     27 => "",

	     # .END
	     30 => "",
	   }
	 }
	}
      )
    end
  end
end
