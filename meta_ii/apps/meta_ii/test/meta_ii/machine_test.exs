defmodule MetaII.Machine.Test do
  use ExUnit.Case, async: true
  doctest MetaII.Machine

  alias MetaII.Machine

  describe "Machine.step/2" do
    test "unrecognized op returns error" do
      {:error, reason} = Machine.step(%{}, :not_a_real_op)
      assert String.contains?(reason, inspect :not_a_real_op)
    end

    test "test: input matches argument string" do
      %{input: "rld", switch: true} =
	%{input: "  hello world"}
	|> Machine.step({:test, "hello wo"})
    end

    test "test: input doesn't match argument string" do
      %{switch: false} =
	%{input: "  hello world"}
	|> Machine.step({:test, "bye"})
    end
  end
end
