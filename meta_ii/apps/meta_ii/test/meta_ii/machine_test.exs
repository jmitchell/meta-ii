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
      actual = Machine.step(%{input: "  hello world"}, {:test, "hello wo"})
      assert %{input: "rld", switch: true} = actual
    end

    test "test: input doesn't match argument string" do
      actual = Machine.step(%{input: "  hello world"}, {:test, "bye"})
      assert %{input: "hello world", switch: false} = actual
    end

    test "identifier: input starts with an identifier" do
      actual = Machine.step(%{input: "  abc123 ...after"}, :identifier)
      assert %{input: " ...after", switch: true} = actual
    end

    test "identifier: input doesn't start with an identifier" do
      actual = Machine.step(%{input: "  5abc123 ."}, :identifier)
      assert %{input: "5abc123 .", switch: false} = actual
    end

    test "number: input starts with a number" do
      actual = Machine.step(%{input: "  12345 ...after"}, :number)
      assert %{input: " ...after", switch: true} = actual
    end

    test "number: input doesn't start with a number" do
      actual = Machine.step(%{input: "  .01 ."}, :number)
      assert %{input: ".01 .", switch: false} = actual
    end

    test "string: input starts with a string" do
      actual = Machine.step(%{input: "  'i am a string.' ..after"}, :string)
      assert %{input: " ..after", switch: true} = actual
    end

    test "string: input doesn't start with a string" do
      actual = Machine.step(%{input: "  'missing an endqoute..."}, :string)
      assert %{input: "'missing an endqoute...", switch: false} = actual
    end

  end
end
