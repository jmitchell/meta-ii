defmodule MetaII.Compiler do
  def meta_ii_impl do
    """
    .SYNTAX PROGRAM

    OUT1 = '*1' .OUT('GN1') / '*2' .OUT('GN2') /
    '*' .OUT('CI') / .STRING .OUT('CL ' *).,

    OUTPUT = ('.OUT' '('
    $ OUT1 ')' / '.LABEL' .OUT('LB') OUT1) .OUT('OUT') .,

    EX3 = .ID .OUT ('CLL' *) / .STRING
    .OUT('TST' *) / '.ID' .OUT('ID') /
    '.NUMBER' .OUT('NUM') /
    '.STRING' .OUT('SR') / '(' EX1 ')' /
    '.EMPTY' .OUT('SET') /
    '$' .LABEL *1 EX3
    .OUT ('BT ' *1) .OUT('SET').,

    EX2 = (EX3 .OUT('BF ' *1) / OUTPUT)
    $(EX3 .OUT('BE') / OUTPUT)
    .LABEL *1 .,

    EX1 = EX2 $('/' .OUT('BT ' *1) EX2 )
    .LABEL *1 .,

    ST = .ID .LABEL * '=' EX1
    '.,' .OUT('R').,

    PROGRAM = '.SYNTAX' .ID .OUT('ADR' *)
    $ ST '.END' .OUT('END').,

    .END
    """
  end

  def parse(src) when is_binary(src) do
    state =
      %{
	lines: src |> String.split("\n"),
	line_num: 0,
	parse: %{},
      } |> parse_program
    case state do
      %{parse: result} -> {:ok, result}
      error -> error
    end
  end

  defp parse_program(state) do
    state
    |> parse_syntax_line
    |> parse_statements
  end

  defp parse_syntax_line(state) do
    {:ok, line, state} = read_line(state)

    case line |> eat_blanks do
      "" ->
	state |> parse_syntax_line
      <<".SYNTAX ", start_label::binary>> ->
	state |> record({:_syntax, start_label |> eat_blanks})
      _ ->
	{:error, "Missing .SYNTAX directive!"}
    end
  end

  defp parse_statements({:error, _} = e), do: e
  defp parse_statements(state) do
    {:ok, line, state} = read_line(state)

    case line |> eat_blanks do
      "" ->
	state |> parse_statements
      ".END" ->
	state |> record(:_end)
      st ->
	state |> parse_statement(st) |> parse_statements
    end
  end

  defp parse_statement(%{line_num: n} = state, st) do
    # TODO
    state
  end

  defp read_line(%{lines: [l | ls], line_num: n} = state) do
    {:ok, l, %{state | lines: ls, line_num: n + 1}}
  end

  defp eat_blanks(s), do: String.trim_leading(s)

  defp update(state, k, v), do: Map.put(state, k, v)

  defp record(state, output, line_num \\ nil) do
    line_num = if line_num == nil do state.line_num else line_num end
    update(state, :parse, Map.put(state.parse, line_num, output))
  end
end
