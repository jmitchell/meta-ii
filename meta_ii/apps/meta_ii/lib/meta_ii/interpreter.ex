defmodule MetaII.Interpreter do

  alias MetaII.Machine
  
  def interpret(compiler, input) when is_binary(compiler) and is_binary(input) do
    IO.puts "INTERPET/2"
    IO.puts "  compiler: #{compiler}"
    IO.puts "  input: #{input}"

    %{
      compiler: compiler |> MetaII.Parser.parse,
      input: input
    } |> program
  end

  def program(%{compiler: {{:program, start_label, _}, _}} = state) do
    IO.puts "PROGRAM"
    IO.puts "  start label: #{start_label}"
    state
    |> statement(start_label)
    |> d(msg: "end of interpreter")
  end

  def statement(%{compiler: {{:program, _, statements}, _}} = state, label) when is_binary(label) do
    with {:ok, st} <- find_statement(statements, label),
         {:ok, state} <- state |> statement(st),
         do: state
  end
  def statement(state, {:st, label, ex1}) do
    IO.puts "STATEMENT: '#{label}'"
    IO.puts "  ex1: #{inspect ex1}"
    IO.puts "  state: #{inspect state}"
    expression1(state, ex1)
  end

  def expression1(state, {:ex1, first, rest}) do
    IO.puts "EXPRESSION1"
    IO.puts "  ex2 (first): #{inspect first}"
    IO.puts "  ex2 (rest): #{inspect rest}"

    state
    |> alternation([first | rest])
  end

  def alternation(state, [h | t]) do
    IO.puts "EXPRESSION1 (try alt)"
    IO.puts "  h: #{inspect h}"
    IO.puts "  t: #{inspect t}"

    case state |> expression2(h) do
      :error ->
	state |> alternation(t)
      result ->
	result
    end
  end
  def alternation(_state, []), do: :error

  def expression2(state, {:ex2, first, rest}) do
    IO.puts "EXPRESSION2 (first)"
    IO.puts "  ex3/out (first): #{inspect first}"
    IO.puts "  ex3/out (rest): #{inspect rest}"

    ex3_or_out = fn state, eo ->
      case kind(eo) do
	:ex3 ->
	  state
	  |> expression3(eo)
	:output ->
	  state
	  |> output(eo)
      end
    end
    
    Enum.reduce(
      rest,
      state |> ex3_or_out.(first),
      fn eo, st ->
	st |> ex3_or_out.(eo)
      end)
  end
  def expression2(state, [h | t]) do
    IO.puts "EXPRESSION2 (rest)"
    IO.puts "  h: #{inspect h}"
    IO.puts "  t: #{inspect t}"
    state
    |> expression2(h)
    |> expression2(t)
  end
  def expression2(state, []), do: state

  def expression3(state, {:ex3, :_id, label}) do
    IO.puts "EXPRESSION3"
    IO.puts "  call .ID: #{label}"
    state
    |> statement(label)
  end
  def expression3(state, {:ex3, :_string, literal}) do
    state
    |> Machine.step({:test, literal})
  end
  def expression3(state, {:ex3, :_paren, ex1}) do
    state
    |> expression1(ex1)
  end
  def expression3(state, {:ex3, :_id}) do
    IO.puts "EXPRESSION3 '.ID'"
    state
    |> Machine.step(:identifier)
    |> IO.inspect
  end
  def expression3(state, {:ex3, :_dollar, body} = ex3) do
    IO.puts "EXPRESSION3"
    IO.puts "||| repetition ($): #{inspect body}"
    try do
      new_state = state |> expression3(body)
      d new_state
      new_state |> expression3(ex3)
    rescue
      e -> d state
    end
  end
  def expression3(state, x) do
    IO.puts "EXPRESSION3"
    IO.puts "  unhandled expression: #{inspect x}"

    d state, stop: true
  end

  # TODO: remove this eventually
  def d(state, opts \\ []) do
    msg = Keyword.get(opts, :msg, "")
    stop = Keyword.get(opts, :stop, false)

    IO.puts "### DEBUG: #{msg}"
    # IO.puts "INPUT: '''#{state[:input]}'''"
    IO.puts "state: #{inspect state}"

    if stop do
      raise "stopped prematurely by toy debugger"
    end

    IO.puts ""
    state
  end

  def output(state, {:output, :_label, o1}) do
    IO.puts "OUTPUT (.LABEL)"
    IO.puts "  o1: #{inspect o1}"
    state
    |> out1(o1)
  end

  def out1(state, {:out1, :_asterisk}) do
    state |> d(stop: true, msg: "out1: *")
  end
  
  def out(%{stdout: stdout} = state, str) do
    %{state | stdout: [stdout | [str]]}
  end

  defp find_statement(statements, label) do
    case statements |> Enum.find(fn {:st, lbl, _} -> lbl == label end) do
      nil -> :error
      st -> {:ok, st}
    end
  end

  defp kind(tup) when is_tuple(tup), do: tup |> Tuple.to_list |> hd
end
