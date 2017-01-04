defmodule MetaII.Parser do
  def parse(src) do
    case src |> String.split("\n") |> parse(1, %{}) do
      {:ok, lines} ->
	%{lines: lines}
      error ->
	error
    end
  end
  defp parse([l | ls], line_num, code) do
    case parse_line(l) do
      {:ok, c} ->
	parse(ls, line_num + 1, Map.put(code, line_num, c))
      error ->
	error
    end
  end
  defp parse([], _, code), do: {:ok, code}

  defp parse_line(line) do
    {:ok, line}
  end
end
