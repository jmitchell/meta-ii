defmodule MetaII.Interpreter.Test do
  use ExUnit.Case, async: true
  doctest MetaII.Interpreter
  alias MetaII.Interpreter

  describe "Interpreter.interpret/2" do
    test "call another rule" do
      compiler =
      """
      .SYNTAX S
      S = T .,
      T = 'abc' .,
      .END
      """

      input = "    abc ..."

      assert %{input: " ..."} = Interpreter.interpret(compiler, input)
    end

    test "literal input" do
      compiler =
      """
      .SYNTAX S
      S = 'abc' .,
      .END
      """

      input = "    abc ..."

      assert %{input: " ..."} = Interpreter.interpret(compiler, input)
    end

    test ".ID .LABEL *" do
      compiler =
      """
      .SYNTAX START
      START = .ID .LABEL * .,
      .END
      """

      input = "   ABC ..."

      assert %{input: " ...", output: "ABC\n"} = Interpreter.interpret(compiler, input)
    end


    @tag :skip
    test "interpret example VALGOL I program" do
      actual =
	ValgolI.Compiler.meta_ii_impl
	|> Interpreter.interpret(ValgolI.Compiler.Test.example_program)
      assert %{} = actual
    end
  end
end
