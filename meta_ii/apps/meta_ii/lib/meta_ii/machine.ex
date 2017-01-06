defmodule MetaII.Machine do
  @bytes_per_instruction 4

  def parse(_src) do
    {:error, "TODO: parse src to produce a state Map"}
  end

  def interpret(state) do
    state |> step |> interpret
  end

  def step(state) do
    case read_current_op(state) do
      {:ok, op} -> step(state, op)
      error -> error
    end
  end
  def step(state, {:test, str}), do: state |> match_input(str) |> increment_pc
  def step(state, :identifier), do: state |> match_input(~S(\p{L}\p{Xan}*)) |> increment_pc
  def step(state, :number), do: state |> match_input(~S(\d+)) |> increment_pc
  def step(state, :string), do: state |> match_input(~S('[^']*')) |> increment_pc
  def step(%{pc: pc, stack: stk} = state, {:call, address}) do
    exit_addr = pc + @bytes_per_instruction
    new_stack =
      case stk do
        [nil, nil | s] ->
          [nil, nil, %{push_count: 1, exit: exit_addr} | s]
        s ->
          [nil, nil, %{push_count: 3, exit: exit_addr} | s]
      end
    %{state | pc: address, stack: new_stack}
  end
  def step(%{stack: [_, _, %{push_count: n, exit: addr} | stk]} = state, :return) do
    case n do
      1 -> %{state | pc: addr, stack: [nil, nil | stk]}
      3 -> %{state | pc: addr, stack: stk}
      _ -> {:error, "Invalid stack :push_count: #{n}"}
    end
  end
  def step(%{pc: _, stack: [_, _, %{push_count: n, exit: addr}]} = state, :return) do
    case n do
      1 -> %{state | pc: addr, stack: [nil, nil]}
      3 -> %{state | pc: addr, stack: []}
      _ -> {:error, "Invalid stack :push_count: #{n}"}
    end
  end
  def step(state, :set) do
    state |> update(:switch, true) |> increment_pc
  end
  def step(state, {:branch, address}) do
    state |> update(:pc, address)
  end
  def step(%{switch: sw} = state, {:branch_true, address}) do
    if sw do state |> update(:pc, address) else state |> increment_pc end
  end
  def step(%{switch: sw} = state, {:branch_false, address}) do
    if sw do state |> increment_pc else state |> update(:pc, address) end
  end
  def step(%{switch: sw} = state, :branch_error) do
    if sw do state |> increment_pc else {:halt, "Branched to error with state:\n#{inspect state}"} end
  end
  def step(state, {:copy_literal, str}) do
    %{state | output: [Map.get(state, :output, []) | [str <> " "]]}
    |> increment_pc
  end
  def step(%{input: i} = state, :copy_input) do
    %{state | output: [Map.get(state, :output, []) | [i]]}
    |> increment_pc
  end
  def step(state, :generate1) do
    state = state |> generate_next
    label = generated_label(state)

    case state do
      %{output: out, stack: [a, nil | c]} ->
        %{state | output: [out | [label <> " "]], stack: [a, label | c]}
        |> increment_pc
      %{output: out, stack: [_, b | _]} ->
        %{state | output: [out | [b <> " "]]}
        |> increment_pc
    end
  end
  def step(state, :generate2) do
    state = state |> generate_next
    label = generated_label(state)

    case state do
      %{output: out, stack: [nil, b | c]} ->
        %{state | output: [out | [label <> " "]], stack: [label, b | c]}
      %{output: out, stack: [a, _ | _]} ->
        %{state | output: [out | [a <> " "]]}
    end
    |> increment_pc
  end
  def step(state, :label) do
    state |> update(:output_col, 1) |> increment_pc
  end
  def step(state, :output) do
    prefix =
      String.duplicate(" ", Map.get(state, :output_col, 1) - 1)
    card =
      Map.get(state, :card, "") <> prefix <> output_string(state)

    state
    |> update(:card, card)
    |> update(:output_col, 8)
    |> increment_pc
  end
  # def step(state, {:address, ident}) do

  # end
  def step(state, :end), do: state
  def step(_state, op) do
    {:error, "Unrecognized op #{inspect op}"}
  end

  defp read_current_op(_state) do
    {:error, "TODO: read current op from PC"}
  end

  defp update(state, key, val), do: Map.put(state, key, val)

  defp trimmed_input(state), do: String.trim_leading(state[:input])

  defp match_input(state, re_str) do
    input = trimmed_input(state)
    case Regex.run(~r/\A(#{re_str})(.*)/s, input) do
      [_, m, r] ->
	state
	|> update(:match_buffer, m)
	|> update(:input, r)
	|> update(:switch, true)
      _ ->
	state
	|> update(:match_buffer, "")
	|> update(:input, input)
	|> update(:switch, false)
    end
  end

  defp increment_pc(state) do
    state |> update(:pc, Map.get(state, :pc, 0) + @bytes_per_instruction)
  end

  defp generate_next(%{gen: %{alpha_prefix: s, n: n}} = state) do
    if n <= 99 do
      %{state | gen: %{alpha_prefix: s, n: n + 1}}
    else
      new_s =
        if s < "Z" do
          to_string [s |> to_charlist |> List.first |> Kernel.+(1)]
        else
          "A"
        end
      # TODO: prevent infinite loop by making longer `alpha_prefix`s
      # as needed

      %{state | gen: %{alpha_prefix: new_s, n: 0}}
    end
  end
  defp generate_next(state) do
    Map.put(state, :gen, %{alpha_prefix: "A", n: 0})
  end

  defp generated_label(%{gen: %{alpha_prefix: s, n: n}}) do
    s <> (n |> Integer.to_string |> String.rjust(2, ?0))
  end

  defp output_string(state) do
    state
    |> Map.get(:output, [""])
    |> List.flatten
    |> Enum.join
  end
end
