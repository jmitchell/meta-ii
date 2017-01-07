defmodule MetaII.Machine do
  @bytes_per_instruction 4
  @bytes_per_word 4
  @print_area_size 100

  def interpret(src, input) when is_binary(src) and is_binary(input) do
    src
    |> parse
    |> Map.put(:input, input)
    |> Map.put(:output, [""])
    |> Map.put(:pc, 0)
    |> interpret
  end
  def interpret(state) do
    case state |> step do
      {:ok, state} ->
        state |> interpret
      {:ok, :end, state} ->
        state
      error ->
        error
    end
  end

  defp parse(src) when is_binary(src) do
    src
    |> String.split("\n")
    |> parse(%{address: 0, instructions: %{}, labels: %{}})
    |> Map.delete(:address)
    |> dereference_labels
  end
  def parse([h | t], context) do
    new_context = if String.trim(h) == "" do
      context
    else
      case h |> String.trim_trailing |> parse_line do
        {:ok, {:op, code}} ->
          %{context |
            instructions: Map.put_new(context.instructions, context.address, code),
            address: next_instruction_addr(context.address, code)}
        {:ok, {:label, label}} ->
          # TODO: ensure label isn't already used
          %{context |
            labels: Map.put_new(context.labels, label, context.address)}
        error -> error
      end
    end

    with {:ok, result} <- parse(t, new_context),
      do: result
  end
  def parse([], context), do: context

  defp parse_line(" " <> op) do
    case parse_op(op) do
      {:error, reason} -> {:error, reason}
      :error -> {:error, "Encountered some kind of error"}
      op_code -> {:ok, {:op, op_code}}
    end
  end
  defp parse_line(label) do
    {:label, label}
  end

  defp parse_op(" " <> op), do: parse_op(op)
  defp parse_op("TST" <> str), do: parse_string(:test, str)
  defp parse_op("BE"), do: :branch_error
  defp parse_op("CL " <> str), do: parse_string(:copy_literal, str)
  defp parse_op("CI"), do: :copy_input
  defp parse_op("OUT"), do: :output
  defp parse_op("END"), do: :end
  defp parse_op(x), do: {:error, "Unrecognized assembly op code: #{x}"}

  defp parse_string(op, " " <> s), do: parse_string(op, s)
  defp parse_string(op, "'" <> str) do
    case Regex.run(~r/^([^']*)'/, str) do
      nil -> {:error, "Invalid string; missing end quote"}
      [_, s] -> {op, s}
    end
  end


  # defp next_instruction_addr(addr, :equal), do: addr + 1
  # defp next_instruction_addr(addr, :multiply), do: addr + 1
  # defp next_instruction_addr(addr, :add), do: addr + 1
  # defp next_instruction_addr(addr, :subtract), do: addr + 1
  # defp next_instruction_addr(addr, :print), do: addr + 1
  # defp next_instruction_addr(addr, :halt), do: addr + 1
  # defp next_instruction_addr(addr, :end), do: addr + 1
  # defp next_instruction_addr(addr, {:block, n}), do: addr + (n * 8)
  # defp next_instruction_addr(addr, {:load_literal, _}), do: addr + 9
  # defp next_instruction_addr(addr, {:edit, _}), do: addr + 2
  # defp next_instruction_addr(addr, {:space, n}), do: addr + n
  defp next_instruction_addr(addr, _code), do: addr + @bytes_per_word

  defp dereference_labels(assembly) do
    deref = fn
      {addr, {op, {:label_ref, ref}}} ->
        case Map.get(assembly.labels, ref) do
          nil -> {:error, "Unrecognized label reference: '#{ref}'"}
          label_addr -> {:ok, {addr, {op, label_addr}}}
        end
      {addr, instr} -> {:ok, {addr, instr}}
    end

    instructions =
      Enum.reduce(assembly.instructions, {:ok, %{}}, fn {addr, _} = instr, acc ->
        with {:ok, acc} <- acc,
             {:ok, instr} <- deref.(instr) do
          {:ok, Map.put(acc, addr, instr)}
        end
      end)

    with {:ok, instructions} <- instructions do
      %{assembly | instructions: instructions}
    end
  end

  defp read_current_op(%{instructions: instrs, pc: pc}) do
    case instrs |> Map.get(pc) do
      {_addr, instr} -> {:ok, instr}
      _ -> {:error, "No instruction found at PC address '#{inspect pc}'"}
    end
  end

  def step(state) do
    case state |> read_current_op do
      {:error, reason} -> {:error, reason}
      {:ok, :end} ->
        {:ok, :end, state}
      {:ok, op} ->
        case step(state, op) do
          {:error, reason} -> {:error, reason}
          :error -> :error
          new_state -> {:ok, new_state}
        end
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
  def step(%{delete_buffer: b} = state, :copy_input) do
    %{state | output: [Map.get(state, :output, []) | [b]]}
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
  def step(_state, op) do
    {:error, "Unrecognized op #{inspect op}"}
  end

  defp update(state, key, val), do: Map.put(state, key, val)

  defp trimmed_input(state), do: String.trim_leading(state[:input])

  defp match_input(state, re_str) do
    input = state |> trimmed_input

    case Regex.run(~r/\A(#{re_str})(.*\Z)/s, input) do
      [_, input, rest] ->
        state
        |> update(:delete_buffer, input)
        |> update(:input, rest)
        |> update(:switch, true)
      _ ->
        state
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
