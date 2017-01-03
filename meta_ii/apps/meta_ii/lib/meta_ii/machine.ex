defmodule MetaII.Machine do
  @bytes_per_instruction 4

  def parse(src) do
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
  def step(state, {:test, str}), do: match_input(state, str) |> increment_pc
  def step(state, :identifier), do: match_input(state, ~S(\p{L}\p{Xan}*)) |> increment_pc
  def step(state, :number), do: match_input(state, ~S(\d+)) |> increment_pc
  def step(state, :string), do: match_input(state, ~S('[^']*')) |> increment_pc
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
  def step(%{pc: pc, stack: [a, b, %{push_count: n, exit: addr} | stk]} = state, :return) do
    case n do
      1 -> %{state | pc: addr, stack: [nil, nil | stk]}
      3 -> %{state | pc: addr, stack: stk}
      _ -> {:error, "Invalid stack :push_count: #{n}"}
    end
  end
  def step(%{pc: pc, stack: [a, b, %{push_count: n, exit: addr}]} = state, :return) do
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
  # def step(state, {:copy_literal, str}) do

  # end
  # def step(state, :copy_input) do

  # end
  # def step(state, :generate1) do

  # end
  # def step(state, :generate2) do

  # end
  # def step(state, :label) do

  # end
  # def step(state, :output) do

  # end
  # def step(state, {:address, ident}) do

  # end
  # def step(state, :end) do

  # end
  def step(state, op) do
    {:error, "Unrecognized op #{inspect op}"}
  end

  defp read_current_op(state) do
    {:error, "TODO: read current op from PC"}
  end

  defp update(state, key, val), do: Map.put(state, key, val)

  defp trimmed_input(state), do: String.trim_leading(state[:input])

  defp match_input(state, re_str) do
    input = trimmed_input(state)
    re = ~r/\A#{re_str}/
    new_input = Regex.replace(re, input, "", global: false)

    # IO.puts """
    # input: #{input}
    # new_input: #{new_input}
    # regex: #{inspect re}
    # match?: #{Regex.match? re, input}
    # """

    state
    |> update(:input, new_input)
    |> update(:switch, new_input != input)
  end

  defp increment_pc(state) do
    state |> update(:pc, Map.get(state, :pc, 0) + @bytes_per_instruction)
  end
end
