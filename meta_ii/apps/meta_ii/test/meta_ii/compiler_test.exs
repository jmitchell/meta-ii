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

    {:ok, result} = MetaII.Machine.interpret(meta_ii_machine, input)
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
