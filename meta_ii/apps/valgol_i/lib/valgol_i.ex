defmodule ValgolI do
  @bytes_per_word 4

  def parse_assembly(lines) when is_list(lines) do
    parse_assembly(lines, %{instructions: [], address: 0, labels: %{}})
  end
  defp parse_assembly([h | t], context) do
    case parse_assembly_line(h) do
      {:op, code} ->
	parse_assembly(t, %{context |
			    instructions: [code | context.instructions],
			    address: next_address(context.address)})
      {:label, label} ->
	parse_assembly(t, %{context |
			    labels: Map.put_new(context.labels, label, context.address)})
      {:error, reason} -> {:error, reason}
    end
  end
  defp parse_assembly([], context) do
    %{context | instructions: Enum.reverse(context.instructions)}
    |> dereference_labels
  end

  defp dereference_labels(assembly) do
    IO.inspect assembly
    {:error, "TODO"}
  end

  defp next_address(addr), do: addr + @bytes_per_word

  def parse_assembly_line(" " <> op) do
    case parse_op(op) do
      {:error, reason} -> {:error, reason}
      :error -> {:error, "Encountered some kind of error"}
      op_code -> {:op, op_code}
    end
  end
  def parse_assembly_line(label) do
    {:label, label}
  end

  defp parse_op(" " <> op), do: parse_op(op)
  defp parse_op("LD " <> loc), do: {:load, {:location, loc}}
  defp parse_op("LDL " <> lit) do
    case Float.parse(lit) do
      {num, _} -> {:load_literal, num}
      _ -> {:error, "LDL opcode expects a literal number argument, not '#{lit}'."}
    end
  end
  defp parse_op("ST " <> loc), do: {:store, {:location, loc}}
  defp parse_op("ADD"), do: :add
  defp parse_op("SUB"), do: :subtract
  defp parse_op("MLT"), do: :multiply
  defp parse_op("EQU"), do: :equal
  defp parse_op("B " <> loc), do: {:branch, {:location, loc}}
  defp parse_op("BFP " <> loc), do: {:branch_false, {:location, loc}}
  defp parse_op("BTP " <> loc), do: {:branch_true, {:location, loc}}
  defp parse_op("EDT " <> str), do: {:edit, str}
  defp parse_op("PNT"), do: :print
  defp parse_op("HLT"), do: :halt
  defp parse_op("SP " <> n) do
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
end
