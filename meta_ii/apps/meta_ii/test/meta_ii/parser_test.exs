defmodule MetaII.Parser.Test do
  use ExUnit.Case, async: true
  doctest MetaII.Parser

  alias MetaII.Parser

  defmacro assert_match(actual, expected) do
    quote do
      assert match?(unquote(expected), unquote(actual))
    end
  end

  describe "Parser.parse/1" do
    test "minimal compiler program" do
      """
      .SYNTAX PROGRAM

      PROGRAM = .,

      .END
      """
      |> Parser.parse
      |> assert_match(
	%{
	  lines: %{
	    # TODO: decide on AST and implement an improved
	    # Parser.parse_line/1
	    1 => ".SYNTAX PROGRAM",
	    3 => "PROGRAM = .,",
	    5 => ".END",
	  }
	})
    end
  end
end
