defmodule MetaII.Compiler.Test do
  use ExUnit.Case, async: true
  doctest MetaII.Compiler

  test "bootstrap" do
    compiler = MetaII.Compiler.meta_ii_machine
    input = MetaII.Compiler.meta_ii_impl

    IO.puts "Compiler machine: \n'''\n#{compiler}\n'''"

    IO.inspect MetaII.Machine.interpret(compiler, input)
  end
end
