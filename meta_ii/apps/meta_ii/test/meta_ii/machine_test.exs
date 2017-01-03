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

    test "call: enter subroutine at address when stack has two blanks" do
      actual = %{
	pc: 32,
	memory: %{16 => :dummy_subroutine},
	stack: [nil, nil, :filler],
      } |> Machine.step({:call, 16})
      assert %{pc: 16,
	       stack: [nil, nil, %{push_count: 1, exit: 32 + 4}, :filler]} = actual
    end

    test "call: enter subroutine at address when stack doesn't have two blanks" do
      actual = %{
	pc: 32,
	memory: %{16 => :dummy_subroutine},
	stack: [:filler],
      } |> Machine.step({:call, 16})
      assert %{pc: 16,
	       stack: [nil, nil, %{push_count: 3, exit: 32 + 4}, :filler]} = actual
    end

    test "return: leave a subroutine when push_count == 1" do
      actual = %{
	pc: 16,
	memory: %{16 => :dummy_subroutine},
	stack: [:a, :b, %{push_count: 1, exit: 36}, :filler],
      } |> Machine.step(:return)
      assert %{pc: 36,
	       stack: [nil, nil, :filler]} = actual
    end

    test "return: leave a subroutine when push_count == 3" do
      actual = %{
	pc: 16,
	memory: %{16 => :dummy_subroutine},
	stack: [:a, :b, %{push_count: 3, exit: 36}, :filler],
      } |> Machine.step(:return)
      assert %{pc: 36,
	       stack: [:filler]} = actual
    end
  end
end
