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
      actual = Machine.step(%{input: "  hello world", pc: 12}, {:test, "hello wo"})
      assert %{input: "rld", switch: true, pc: 16} = actual
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

    test "set: turn branch switch on" do
      assert %{switch: true} = %{switch: false} |> Machine.step(:set)
      assert %{switch: true} = %{switch: true} |> Machine.step(:set)
    end

    test "branch: set program counter to specified address" do
      assert %{pc: 64} = %{pc: 100} |> Machine.step({:branch, 64})
    end

    test "branch_true: set program counter to specified address" do
      assert %{pc: 64} = %{pc: 100, switch: true} |> Machine.step({:branch_true, 64})
      assert %{pc: 104} = %{pc: 100, switch: false} |> Machine.step({:branch_true, 64})
    end

    test "branch_false: set program counter to specified address" do
      assert %{pc: 64} = %{pc: 100, switch: false} |> Machine.step({:branch_false, 64})
      assert %{pc: 104} = %{pc: 100, switch: true} |> Machine.step({:branch_false, 64})
    end

    test "branch_error: halt when switch is off" do
      assert {:halt, _} = %{switch: false} |> Machine.step(:branch_error)
      assert %{pc: 36} = %{pc: 32, switch: true} |> Machine.step(:branch_error)
    end

    test "copy_literal: output variable length string" do
      actual = %{
        output: ["dummy "]
      } |> Machine.step({:copy_literal, "abc"})
      assert %{output: [["dummy "] | ["abc "]]} = actual
    end

    test "copy_input: output the remaining input" do
      actual = %{
        input: "the end.",
        output: ["dummy "],
      } |> Machine.step(:copy_input)
      assert %{output: [["dummy "] | ["the end."]]} = actual
    end

    test "generate1: generate and output a new label" do
      actual = %{
        stack: [:a, nil, 1, 2, 3],
        output: ["dummy "],
      } |> Machine.step(:generate1)
      assert %{stack: [:a, "A00", 1, 2, 3],
               output: [["dummy "] | ["A00 "]],
               gen: %{alpha_prefix: "A", n: 0}} = actual
    end

    test "generate2: generate and output a new label" do
      actual = %{
        stack: [nil, :b, 1, 2, 3],
        output: ["dummy "],
      } |> Machine.step(:generate2)
      assert %{stack: ["A00", :b, 1, 2, 3],
               output: [["dummy "] | ["A00 "]],
               gen: %{alpha_prefix: "A", n: 0}} = actual
    end

    test "label: set output counter to card column 1" do
      actual = %{
        output_col: 5
      } |> Machine.step(:label)
      assert %{output_col: 1} = actual
    end

    test "output: punch card and reset output counter to card column 8." do
      actual = %{
        output: [[[["this "] | ["is "]] | ["a "]] | ["test "]],
        output_col: 3,
        card: "",
      } |> Machine.step(:output)
      assert %{card: "  this is a test ", output_col: 8} = actual
    end

    @tag :skip
    test "address: produce the address which is assigned to the given identifier as a constant" do
      flunk "need to make a second pass through the addressable memory"
      # TODO: refactor META II interpreter so it operates on lines of
      # source code instead of bytes of memory (e.g. remove
      # @bytes_per_instruction).
    end

    test "end: denotes the end of the program" do
      actual = %{dummy_state: [1,2,3]} |> Machine.step(:end)
      assert %{dummy_state: [1,2,3]} = actual
    end
  end
end
