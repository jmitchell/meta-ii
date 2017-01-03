defmodule ValgolI.Machine do
  @bytes_per_word 4
  @print_area_size 100

  def parse(src) when is_binary(src) do
    src
    |> String.split("\n")
    |> parse(%{address: 0, instructions: %{}, labels: %{}})
    |> dereference_labels
  end
  def parse([h | t], context) do
    if String.trim(h) == "" do
      parse(t, context)
    else
      case h |> String.trim_trailing |> parse_line do
	{:op, code} ->
	  parse(t, %{context |
		     instructions: Map.put_new(context.instructions, context.address, code),
		     address: next_instruction_addr(context.address, code)})
	{:label, label} ->
	  # TODO: ensure label isn't already used
	  parse(t, %{context |
		     labels: Map.put_new(context.labels, label, context.address)})
	{:error, reason} -> {:error, reason}
      end
    end
  end
  def parse([], context), do: context

  def interpret(memory) when is_map(memory) do
    step(%{memory: memory})
  end

  defp step(state) when is_map(state) do
    state =
      state
      |> Map.put_new(:pc, 0)
      |> Map.put_new(:stack, [])
      |> Map.put_new_lazy(:print_area, &clean_print_area/0)
      |> Map.put_new(:output, [])

    op = Map.get(state[:memory], state[:pc])

    update = fn state, kw, update_fn ->
      {_, new_state} = Map.get_and_update(state, kw, fn val -> {val, update_fn.(val)} end)
      new_state
    end
    advance_pc = state |> update.(:pc, fn pc ->
      next_instruction_addr(pc, op)
    end)
    branch_when = &(state |> update.(:pc, fn pc -> if &1 do &2 else next_instruction_addr(pc, op) end end))

    pop_stack = &(&1 |> update.(:stack, fn s -> tl s end))

    case op do
      nil ->
	advance_pc |> step
      {:branch, addr} ->
	branch_when.(true, addr) |> step
      {:block, _n} ->
	advance_pc |> step
      {:load_literal, n} ->
      	advance_pc |> update.(:stack, &[n | &1]) |> step
      {:store, addr} ->
	advance_pc
	|> pop_stack.()
	|> update.(:memory, &(Map.put(&1, addr, hd state[:stack])))
	|> step
      {:load, addr} ->
	case Map.get(state[:memory], addr) do
	  nil -> {:error, "Nothing allocated to address #{addr}"}
	  n -> advance_pc |> update.(:stack, &[n | &1]) |> step
	end
      :equal ->
	advance_pc
	|> update.(:stack, fn [a,b | c] ->
	  precision = 3
	  [if Float.round(a, precision) == Float.round(b, precision) do 1 else 0 end | c]
	end)
	|> step
      {:branch_true, addr} ->
	branch_when.(hd(state[:stack]) != 0, addr)
	|> pop_stack.()
	|> step
      {:branch_false, addr} ->
	branch_when.(hd(state[:stack]) == 0, addr)
	|> pop_stack.()
	|> step
      :add ->
	advance_pc
	|> update.(:stack, fn [a,b | c] -> [a+b | c] end)
	|> step
      :subtract ->
	advance_pc
	|> update.(:stack, fn [a,b | c] -> [b-a | c] end)
	|> step
      :multiply ->
	advance_pc
	|> update.(:stack, fn [a,b | c] -> [a*b | c] end)
	|> step
      {:edit, s} ->
	advance_pc
	|> update.(:print_area, fn pa ->
	  i = state[:stack] |> hd |> round
	  j = i + String.length(s)
	  case (String.length(pa) - j) do
	    n when is_integer(n) and n < 0 -> pa
	    n when is_integer(n) ->
	      front = String.slice(pa, 0, i)
	      back = String.slice(pa, j, n)
	      front <> s <> back
	  end
	end)
	|> step
      :print ->
	advance_pc
	|> update.(:output, &[&1 | [String.trim_trailing(state[:print_area]) <> "\n"]])
	|> update.(:print_area, fn _ -> clean_print_area end)
	|> step
      :halt ->
	advance_pc |> step
      {:space, n} ->
	state
	|> update.(:pc, fn pc -> pc + n end)
	|> step
      :end ->
	state
        |> update.(:output, &(&1 |> List.flatten |> Enum.join))
      _ ->
    	{:error, "Unsupported instruction: #{inspect op}"}
    end
  end

  defp clean_print_area, do: String.duplicate(" ", @print_area_size)

  defp dereference_labels(assembly) do
    deref = fn
      {addr, {op, {:label_ref, ref}}} ->
	case Map.get(assembly.labels, ref) do
	  nil -> {:error, "Unrecognized label reference: '#{ref}'"}
	  label_addr -> {addr, {op, label_addr}}
	end
      other -> other
    end

    assembly.instructions |> Enum.map(deref) |> Enum.into(%{})
  end

  defp next_instruction_addr(addr, :equal), do: addr + 1
  defp next_instruction_addr(addr, :multiply), do: addr + 1
  defp next_instruction_addr(addr, :add), do: addr + 1
  defp next_instruction_addr(addr, :subtract), do: addr + 1
  defp next_instruction_addr(addr, :print), do: addr + 1
  defp next_instruction_addr(addr, :halt), do: addr + 1
  defp next_instruction_addr(addr, :end), do: addr + 1
  defp next_instruction_addr(addr, {:block, n}), do: addr + (n * 8)
  defp next_instruction_addr(addr, {:load_literal, _}), do: addr + 9
  defp next_instruction_addr(addr, {:edit, _}), do: addr + 2
  defp next_instruction_addr(addr, {:space, n}), do: addr + n
  defp next_instruction_addr(addr, _code), do: addr + @bytes_per_word

  defp parse_line(" " <> op) do
    case parse_op(op) do
      {:error, reason} -> {:error, reason}
      :error -> {:error, "Encountered some kind of error"}
      op_code -> {:op, op_code}
    end
  end
  defp parse_line(label) do
    {:label, label}
  end

  defp parse_op(" " <> op), do: parse_op(op)
  defp parse_op("LD  " <> loc), do: parse_location(:load, loc)
  defp parse_op("LDL " <> lit) do
    case Float.parse(lit) do
      {num, _} -> {:load_literal, num}
      _ -> {:error, "LDL opcode expects a literal number argument, not '#{lit}'."}
    end
  end
  defp parse_op("ST  " <> loc), do: parse_location(:store, loc)
  defp parse_op("ADD"), do: :add
  defp parse_op("SUB"), do: :subtract
  defp parse_op("MLT"), do: :multiply
  defp parse_op("EQU"), do: :equal
  defp parse_op("B   " <> loc), do: parse_location(:branch, loc)
  defp parse_op("BFP " <> loc), do: parse_location(:branch_false, loc)
  defp parse_op("BTP " <> loc), do: parse_location(:branch_true, loc)
  defp parse_op("EDT " <> str), do: parse_string(:edit, str)
  defp parse_op("PNT"), do: :print
  defp parse_op("HLT"), do: :halt
  defp parse_op("SP  " <> n) do
    case Integer.parse(n, 10) do
      {n, _} -> {:space, n}
      _ -> {:error, "SP opcode expects an integer argument, not '#{n}'."}
    end
  end
  defp parse_op("BLK " <> n) do
    case Integer.parse(n, 10) do
      {n, _} -> {:block, n}
      _ -> {:error, "BLK opcode expects an integer argument, not '#{n}'."}
    end
  end
  defp parse_op("END"), do: :end
  defp parse_op(x), do: {:error, "Unrecognized assembly op code: #{x}"}

  defp parse_location(op, loc) do
    case Integer.parse(loc, 10) do
      {addr, _} -> {op, {:address, addr}}
      _ -> {op, {:label_ref, loc}}
    end
  end

  defp parse_string(op, <<nn :: bytes-size(2)>> <> "'" <> str) do
    case Integer.parse(nn) do
      {len, _} -> {op, String.slice(str, 0, len)}
      _ -> {:error, "Invalid string length signifier: '#{nn}'"}
    end
  end
end
