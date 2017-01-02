defmodule ValgolI do
  @bytes_per_word 4

  def parse(src) when is_binary(src) do
    src
    |> String.split("\n")
    |> parse(%{instructions: [], address: 0, labels: %{}})
  end
  defp parse([h | t], context) do
    if String.trim(h) == "" do
      parse(t, context)
    else
      case h |> String.trim_trailing |> parse_line do
	{:op, code} ->
	  parse(t, %{context |
		     instructions: [code | context.instructions],
		     address: next_address(context.address)})
	{:label, label} ->
	  parse(t, %{context |
		     labels: Map.put_new(context.labels, label, context.address)})
	{:error, reason} -> {:error, reason}
      end
    end
  end
  defp parse([], context) do
    %{context | instructions: Enum.reverse(context.instructions)}
  end

  defp dereference_labels(assembly) do
    IO.inspect assembly
    {:error, "TODO"}
  end

  defp next_address(addr), do: addr + @bytes_per_word

  def parse_line(" " <> op) do
    case parse_op(op) do
      {:error, reason} -> {:error, reason}
      :error -> {:error, "Encountered some kind of error"}
      op_code -> {:op, op_code}
    end
  end
  def parse_line(label) do
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
  defp parse_op("EDT " <> str), do: {:edit, str}
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
end
