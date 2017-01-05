defmodule MetaII.Parser do

  def parse(src), do: src |> program

  def out1(src) do
    case src |> eat_blanks do
      <<"*1", rest::binary>> ->
	{{:out1, :_gen1}, rest}
      <<"*2", rest::binary>> ->
	{{:out1, :_gen2}, rest}
      <<"*", rest::binary>> ->
	{{:out1, :_asterisk}, rest}
      rest ->
	case rest |> string do
	  {str, rest} ->
	    {{:out1, :_string, str}, rest}
	  _ ->
	    :error
	end
    end
  end

  def output(src) do
    case src |> eat_blanks do
      <<".OUT", rest::binary>> ->
	case rest |> eat_blanks do
	  <<"(", rest::binary>> ->
	    case rest |> sequence(&out1/1) do
	      {out1s, rest} ->
		case rest |> eat_blanks do
		  <<")", rest::binary>> ->
		    {{:output, :_out, out1s}, rest}
		  _ -> :error
		end
	      _ -> :error
	    end
	end
      <<".LABEL", rest::binary>> ->
	case out1(rest) do
	  {out1, rest} ->
	    {{:output, :_label, out1}, rest}
	  _ -> :error
	end
      _ -> :error
    end
  end

  def ex3(src) do
    case src |> eat_blanks do
      <<".ID", rest::binary>> ->
	{{:ex3, :_id}, rest}
      <<".NUMBER", rest::binary>> ->
	{{:ex3, :_number}, rest}
      <<".STRING", rest::binary>> ->
	{{:ex3, :_string}, rest}
      <<"(", rest::binary>> ->
	case rest |> ex1 do
	  {e1, rest} ->
	    {{:ex3, :_paren, e1}, rest}
	  _ ->
	    :error
	end
      <<".EMPTY", rest::binary>> ->
	{{:ex3, :_empty}, rest}
      <<"$", rest::binary>> ->
	case rest |> ex3 do
	  {e3, rest} ->
	    {{:ex3, :_dollar, e3}, rest}
	  _ ->
	    :error
	end
      :error ->
	:error
      <<"/", rest::binary>> ->
	:error
      rest ->
	case rest |> string do
	  {str, rest} ->
	    {{:ex3, :_string, str}, rest}
	  :error ->
	    case rest |> identifier do
	      {".,", rest} ->
		:error
	      {ident, rest} ->
		{{:ex3, :_id, ident}, rest}
	      _ ->
		:error
	    end
	  x ->
	    :error
	end
    end
  end

  def ex2(src) do
    case src |> ex3_or_output do
      {e3_first, rest} ->
	case rest |> sequence(&ex3_or_output/1) do
	  {e3_rest, rest} ->
	    {{:ex2, e3_first, e3_rest}, rest}
	  _ ->
	    :error
	end
      _ ->
	:error
    end
  end

  def ex3_or_output(src) do
    case src |> output do
      {out, rest} ->
	{out, rest}
      _ ->
	src |> ex3
    end
  end

  def ex1(src) do
    case src |> ex2 do
      {e2_first, rest} ->
	case rest |> sequence(&ex2_alternate/1) do
	  {e2_rest, rest} ->
	    {{:ex1, e2_first, e2_rest}, rest}
	  _ ->
	    :error
	end
      _ ->
	:error
    end
  end

  def st(src) do
    case src |> identifier do
      {ident, rest} ->
	case rest |> eat_blanks do
	  <<"=", rest::binary>> ->
	    case rest |> ex1 do
	      {rhs, rest} ->
		case rest |> eat_blanks do
		  <<".,", rest::binary>> ->
		    {{:st, ident, rhs}, rest}
		  _ ->
		    :error
		end
	      _ ->
		:error
	    end
	  _ ->
	    :error
	end
      _ ->
	:error
    end
  end

  def program(<<".SYNTAX ", rest::binary>>) do
    case rest |> identifier do
      {ident, rest} ->
	case rest |> sequence(&st/1) do
	  {stmts, rest} ->
	    case rest |> eat_blanks do
	      <<".END", rest::binary>> ->
		{{:program, ident, stmts}, rest}
	      x ->
		:error
	    end
	  _ ->
	    :error
	end
      _ -> :error
    end
  end


  defp ex2_alternate(:error), do: :error
  defp ex2_alternate(src) do
    case src |> eat_blanks do
      <<"/", rest::binary>> ->
	rest |> ex2
      x ->
	:error
    end
  end

  defp sequence(src, parser, acc \\ []) do
    case parser.(src) do
      :error ->
	{acc |> Enum.reverse, src}
      {result, rest} ->
	rest |> sequence(parser, [result | acc])
      _ ->
	:error
    end
  end

  def string(:error), do: :error
  def string(src) do
    case src |> eat_blanks do
      <<"'", rest::binary>> ->
	case Regex.run(~r/([^']*)'(.*)/s, rest) do
	  [_, str, rest] ->
	    {str, rest}
	  _ ->
	    :error
	end
      _ ->
	:error
    end
  end

  def identifier(:error), do: :error
  def identifier(src) do
    # TODO: stricter definition for the identifier part
    case Regex.run(~r/\A\s*([^\s\/\.]+)(\s.*)\Z/ms, src) do
      [_, ident, rest] ->
	{ident, rest}
      _ ->
	:error
    end
  end

  defp eat_blanks(src), do: src |> String.trim_leading
end
