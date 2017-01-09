defmodule MetaII.Compiler.Test do
  use ExUnit.Case, async: true
  doctest MetaII.Compiler
  alias MetaII.Compiler

  test "EX2: static call, string literals, and output" do
    meta_ii_impl =
    """
    .SYNTAX PROGRAM
    A = 'a' .OUT('found "a"') .,
    B = 'b' .OUT('found "b"') .,
    PROGRAM = A B .,
    .END
    """

    input = "a b"

    meta_ii_machine =
      meta_ii_impl |> Compiler.compile

    {:ok, result} = MetaII.Machine.interpret(meta_ii_machine, input)
    IO.puts "CARD: '''\n#{result.card}\n'''"
    assert result.input == ""
    assert result.output == [""]
    assert result.card == ~s(       found "a" \n       found "b" \n)
  end

  test "EX2: $ string literal" do
    meta_ii_impl =
    """
    .SYNTAX PROGRAM
    PROGRAM = $ 'a' .,
    .END
    """

    input = "a a a"

    meta_ii_machine =
      meta_ii_impl |> Compiler.compile

    {:ok, result} = MetaII.Machine.interpret(meta_ii_machine, input)
    assert result.input == ""
    assert result.output == [""]
  end

  test "EX2: $ 'a' 'b'" do
    meta_ii_impl =
    """
    .SYNTAX PROGRAM
    PROGRAM = $ 'a' 'b' .,
    .END
    """

    input = "a a a b"

    meta_ii_machine =
      meta_ii_impl |> Compiler.compile

    IO.puts "\nMETA II Machine: '''\n#{meta_ii_machine}\n'''"
    IO.puts "\nINPUT: '''\n#{inspect input, pretty: true}\n'''"

    {:ok, result} = MetaII.Machine.interpret(meta_ii_machine, input)
    # IO.puts "\nCARD: '''\n#{result.card}\n'''"
    IO.puts "\nRESULT: #{inspect result, pretty: true}"
    assert result.input == ""
    assert result.output == [""]
  end

  test "EX2: 'b' $ 'a'" do
    meta_ii_impl =
    """
    .SYNTAX PROGRAM
    PROGRAM = 'b' $ 'a' .,
    .END
    """

    input = "b a a a"

    meta_ii_machine =
      meta_ii_impl |> Compiler.compile

    {:ok, result} = MetaII.Machine.interpret(meta_ii_machine, input)
    assert result.input == ""
    assert result.output == [""]
  end

  test "EX2: static call and simple $ EX3" do
    meta_ii_impl =
    """
    .SYNTAX PROGRAM
    A = 'a' .OUT('found "a"') .,
    PROGRAM = $ A .,
    .END
    """

    input = "a a a"

    meta_ii_machine =
      meta_ii_impl |> Compiler.compile

    {:ok, result} = MetaII.Machine.interpret(meta_ii_machine, input)
    IO.puts "CARD: '''\n#{result.card}\n'''"
    assert result.input == ""
    assert result.output == [""]
    assert result.card == ~s(       found "a" \n       found "a" \n       found "a" \n)
  end

  test "EX2: EX3 string literal with $ EX3" do
    meta_ii_impl =
    """
    .SYNTAX PROGRAM
    A = 'a' .OUT('found "a"') .,
    PROGRAM = 'seq' $ A .,
    .END
    """

    input = "seq  a a a"

    meta_ii_machine =
      meta_ii_impl |> Compiler.compile

    {:ok, result} = MetaII.Machine.interpret(meta_ii_machine, input)
    IO.puts "CARD: '''\n#{result.card}\n'''"
    assert result.input == ""
    assert result.output == [""]
    assert result.card == ~s(       found "a" \n       found "a" \n       found "a" \n)
  end

  test "output" do
    meta_ii_impl =
    """
    .SYNTAX PROGRAM
    PROGRAM = .OUT('SET') .,
    .END
    """
    
    input = ""

    meta_ii_machine =
      meta_ii_impl |> Compiler.compile

    assert {:ok, %{input: "", output: [""], card: "       SET \n"}} = MetaII.Machine.interpret(meta_ii_machine, input)
  end

  test "backtracking repetition sequence?" do
    # I don't know yet whether this test is supposed to pass.
    #
    # My reading of the VALGOL I grammar and the example program
    # suggests it should pass, in which case there's a bug in my META
    # II hand-compiled compiler or, less likely, in the META II
    # assembly interpreter. A fix for that would probably involve
    # adding backtracking to repetition sequences (`$`), although such
    # a change must be justified by the META II definition.
    #
    # Alternatively, the test should fail, in which case there may be
    # a bug in the VALGOL I grammar. The fix would involve changing
    # the IDSEQ delimiter, `.`, to a token that doesn't collide with
    # the DEC terminator and patching the example program
    # accordingly. In this test the equivalent would be changing `':'`
    # to, perhaps, `','` and then changing all the `x :` lines in the
    # input to `x ,`.
    meta_ii_impl =
    """
    .SYNTAX
    X = 'x' ':' .,
    PROGRAM = $ X ':end' .OUT('end') .,
    .END
    """

    input =
    """
    x :
    x :
    x :end
    """

    meta_ii_machine =
      meta_ii_impl |> Compiler.compile

    assert {:ok, %{input: "", output: [""], card: "       end \n"}} = MetaII.Machine.interpret(meta_ii_machine, input)
  end

  test "bootstrap" do
    definition = Compiler.meta_ii_impl
    machine = Compiler.meta_ii_machine |> normalize_assembly
    bootstrapped_machine =
      definition
      |> Compiler.compile
      |> normalize_assembly

    assert machine == bootstrapped_machine
  end

  def normalize_assembly(asm) do
    asm
    |> String.split("\n")
    |> Enum.map(&String.trim_trailing/1)
    |> Enum.filter(fn(s) -> s != "" end)
    |> Enum.join("\n")
  end
end
