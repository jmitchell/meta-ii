defmodule MetaII.Parser.Test do
  use ExUnit.Case, async: true
  alias MetaII.Parser
  doctest Parser

  describe "Parser.out1/1" do
    test "'*1'" do
      assert " *1 rest" |> Parser.out1 == {{:out1, :_gen1}, " rest"}
    end

    test "'*2'" do
      assert " *2 rest" |> Parser.out1 == {{:out1, :_gen2}, " rest"}
    end

    test "*" do
      assert " * rest" |> Parser.out1 == {{:out1, :_asterisk}, " rest"}
    end

    test "'a string'" do
      assert " 'a string' rest" |> Parser.out1 == {{:out1, :_string, "a string"}, " rest"}
    end

    test "invalid" do
      assert "not an out1" |> Parser.out1 == :error
    end
  end

  describe "Parser.output/1" do
    test ".OUT" do
      assert " .OUT('ABC' *2) rest" |> Parser.output ==
      {{:output, :_out,
	[{:out1, :_string, "ABC"},
	 {:out1, :_gen2}]}, " rest"}
    end

    test ".LABEL" do
      assert " .LABEL * rest" |> Parser.output ==
      {{:output, :_label, {:out1, :_asterisk}}, " rest"}
    end

    test "invalid" do
      assert " not output" |> Parser.output == :error
    end
  end

  describe "Parser.ex3/1" do
    test "call .ID" do
      assert " LABEL rest" |> Parser.ex3 ==
      {{:ex3, :_id, "LABEL"}, " rest"}
    end

    test "test .STRING" do
      assert " 'a string' rest" |> Parser.ex3 ==
      {{:ex3, :_string, "a string"}, " rest"}
    end

    test "'.ID'" do
      assert " .ID rest" |> Parser.ex3 ==
      {{:ex3, :_id}, " rest"}
    end

    test "'.NUMBER'" do
      assert " .NUMBER rest" |> Parser.ex3 ==
      {{:ex3, :_number}, " rest"}
    end

    test "'.STRING'" do
      assert " .STRING rest" |> Parser.ex3 ==
      {{:ex3, :_string}, " rest"}
    end

    test "'(' EX1 ')'" do
      assert " ( LBL ) rest" |> Parser.ex3 ==
      {{:ex3, :_paren,
	{:ex1,
	 {:ex2,
	  {:ex3, :_id, "LBL"}, []}, []}}, " rest"}
    end

    test "'.EMPTY'" do
      assert " .EMPTY rest" |> Parser.ex3 ==
      {{:ex3, :_empty}, " rest"}
    end

    test "$" do
      assert " $ ST rest" |> Parser.ex3 ==
      {{:ex3, :_dollar,
	{:ex3, :_id, "ST"}}, " rest"}
    end
  end

  describe "Parser.ex2/1" do
    test "EX3 OUTPUT EX3" do
      assert " AB .OUT('XYZ' *1) CD .rest" |> Parser.ex2 ==
      {{:ex2,
	{:ex3, :_id, "AB"},
	[{:output, :_out,
	  [{:out1, :_string, "XYZ"},
	   {:out1, :_gen1}]},
	 {:ex3, :_id, "CD"}]}, " .rest"}
    end
  end

  describe "Parse.ex1/1" do
    test "A / B" do
      assert " AB / C D / EFG .rest" |> Parser.ex1 ==
      {{:ex1,
	{:ex2, {:ex3, :_id, "AB"}, []},
	[{:ex2,
	  {:ex3, :_id, "C"},
	  [{:ex3, :_id, "D"}]},
	 {:ex2, {:ex3, :_id, "EFG"}, []}]}, " .rest"}
    end
  end

  describe "Parse.st/1" do
    test "ABC = DEF .," do
      assert "  ABC = DEF ., rest" |> Parser.st ==
      {{:st, "ABC",
	{:ex1,
	 {:ex2,
	  {:ex3, :_id, "DEF"}, []}, []}}, " rest"}
    end
  end

  describe "Parse.program/1" do
    test "short program" do
      assert """
      .SYNTAX START
      START = 'xyz' .,
      .END rest
      """ |> Parser.program ==
      {{:program, "START",
	[{:st, "START",
	  {:ex1,
	   {:ex2,
	    {:ex3, :_string, "xyz"}, []}, []}}]}, " rest\n"}
    end
  end


  describe "Parser.parse/1" do
    test "parse VALGOL I compiler" do
      actual = ValgolI.Compiler.meta_ii_impl |> Parser.parse
      expected =
      {{:program, "PROGRAM",
	[{:st, "PRIMARY",
	  {:ex1,
	   {:ex2, {:ex3, :_id},
	    [{:output, :_out, [{:out1, :_string, "LD "}, {:out1, :_asterisk}]}]},
	   [{:ex2, {:ex3, :_number},
	     [{:output, :_out, [{:out1, :_string, "LDL"}, {:out1, :_asterisk}]}]},
	    {:ex2, {:ex3, :_string, "("},
	     [{:ex3, :_id, "EXP"},
	      {:ex3, :_string, ")"}]}]}},
	 {:st, "TERM",
	  {:ex1,
	   {:ex2, {:ex3, :_id, "PRIMARY"},
	    [{:ex3, :_dollar,
              {:ex3, :_paren,
               {:ex1,
		{:ex2, {:ex3, :_string, "*"},
		 [{:ex3, :_id, "PRIMARY"},
		  {:output, :_out, [{:out1, :_string, "MLT"}]}]}, []}}}]}, []}},
	 {:st, "EXP1",
	  {:ex1,
	   {:ex2, {:ex3, :_id, "TERM"},
	    [{:ex3, :_dollar,
              {:ex3, :_paren,
               {:ex1,
		{:ex2, {:ex3, :_string, "+"},
		 [{:ex3, :_id, "TERM"}, {:output, :_out, [{:out1, :_string, "ADD"}]}]},
		[{:ex2, {:ex3, :_string, "-"},
		  [{:ex3, :_id, "TERM"},
		   {:output, :_out, [{:out1, :_string, "SUB"}]}]}]}}}]}, []}},
	 {:st, "EXP",
	  {:ex1,
	   {:ex2, {:ex3, :_id, "EXP1"},
	    [{:ex3, :_paren,
              {:ex1,
               {:ex2, {:ex3, :_string, ".*"},
		[{:ex3, :_id, "EXP1"},
		 {:output, :_out,
		  [{:out1, :_string, "EQU"}]}]},
               [{:ex2, {:ex3, :_empty}, []}]}}]}, []}},
	 {:st, "ASSIGNST",
	  {:ex1,
	   {:ex2, {:ex3, :_id, "EXP"},
	    [{:ex3, :_string, "="},
	     {:ex3, :_id},
	     {:output, :_out,
	      [{:out1, :_string, "ST "},
	       {:out1, :_asterisk}]}]}, []}},
	 {:st, "UNTILST",
	  {:ex1,
	   {:ex2, {:ex3, :_string, ".UNTIL"},
	    [{:output, :_label, {:out1, :_gen1}}, {:ex3, :_id, "EXP"},
	     {:ex3, :_string, ".DO"},
	     {:output, :_out, [{:out1, :_string, "BTP"}, {:out1, :_gen2}]},
	     {:ex3, :_id, "ST"},
	     {:output, :_out, [{:out1, :_string, "B  "}, {:out1, :_gen1}]},
	     {:output, :_label, {:out1, :_gen2}}]}, []}},
	 {:st, "CONDITIONALST",
	  {:ex1,
	   {:ex2, {:ex3, :_string, ".IF"},
	    [{:ex3, :_id, "EXP"}, {:ex3, :_string, ".THEN"},
	     {:output, :_out, [{:out1, :_string, "BFP"}, {:out1, :_gen1}]},
	     {:ex3, :_id, "ST"}, {:ex3, :_string, ".ELSE"},
	     {:output, :_out, [{:out1, :_string, "B  "}, {:out1, :_gen2}]},
	     {:output, :_label, {:out1, :_gen1}}, {:ex3, :_id, "ST"},
	     {:output, :_label, {:out1, :_gen2}}]}, []}},
	 {:st, "IOST",
	  {:ex1,
	   {:ex2, {:ex3, :_string, "EDIT"},
	    [{:ex3, :_string, "("}, {:ex3, :_id, "EXP"}, {:ex3, :_string, "."},
	     {:ex3, :_string},
	     {:output, :_out, [{:out1, :_string, "EDT"}, {:out1, :_asterisk}]},
	     {:ex3, :_string, ")"}]},
	   [{:ex2, {:ex3, :_string, ".PRINT"},
	     [{:output, :_out, [{:out1, :_string, "PNT"}]}]}]}},
	 {:st, "IDSEQ1",
	  {:ex1,
	   {:ex2, {:ex3, :_id},
	    [{:output, :_label, {:out1, :_asterisk}},
	     {:output, :_out, [{:out1, :_string, "BLK 1"}]}]}, []}},
	 {:st, "IDSEQ",
	  {:ex1,
	   {:ex2, {:ex3, :_id, "IDSEQ1"},
	    [{:ex3, :_dollar,
              {:ex3, :_paren,
               {:ex1, {:ex2, {:ex3, :_string, "."}, [{:ex3, :_id, "IDSEQ1"}]},
		[]}}}]}, []}},
	 {:st, "DEC",
	  {:ex1,
	   {:ex2, {:ex3, :_string, ".REAL"},
	    [{:output, :_out, [{:out1, :_string, "B  "}, {:out1, :_gen1}]},
	     {:ex3, :_id, "IDSEQ"}, {:output, :_label, {:out1, :_gen1}}]}, []}},
	 {:st, "BLOCK",
	  {:ex1,
	   {:ex2,
	    {:ex3, :_string, ".BEGIN"},
	    [{:ex3, :_paren,
              {:ex1, {:ex2, {:ex3, :_id, "DEC"}, [{:ex3, :_string, ".,"}]},
               [{:ex2, {:ex3, :_empty}, []}]}},
	     {:ex3, :_id, "ST"},
	     {:ex3, :_dollar,
	      {:ex3, :_paren,
	       {:ex1,
		{:ex2,
		 {:ex3, :_string, ".,"},
                 [{:ex3, :_id, "ST"}]}, []}}},
	     {:ex3, :_string, ".END"}]}, []}},
	 {:st, "ST",
	  {:ex1, {:ex2, {:ex3, :_id, "IOST"}, []},
	   [{:ex2, {:ex3, :_id, "ASSIGNST"}, []}, {:ex2, {:ex3, :_id, "UNTILST"}, []},
	    {:ex2, {:ex3, :_id, "CONDITIONALST"}, []},
	    {:ex2, {:ex3, :_id, "BLOCK"}, []}]}},
	 {:st, "PROGRAM",
	  {:ex1,
	   {:ex2, {:ex3, :_id, "BLOCK"},
	    [{:output, :_out, [{:out1, :_string, "HLT"}]},
	     {:output, :_out, [{:out1, :_string, "SP  1"}]},
	     {:output, :_out, [{:out1, :_string, "END"}]}]}, []}}]}, " \n"}

      assert expected == actual
    end
  end

end
