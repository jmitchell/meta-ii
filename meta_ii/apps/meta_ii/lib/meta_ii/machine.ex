defmodule MetaII.Machine do

  def step(state) do
    case read_current_op(state) do
      {:ok, op} -> state |> step(op) |> step
      error -> error
    end
  end
  def step(state, {:test, str}), do: match_input(state, str)
  def step(state, :identifier), do: match_input(state, ~S(\p{L}\p{Xan}*))
  def step(state, :number), do: match_input(state, ~S(\d+))
  def step(state, :string), do: match_input(state, ~S('[^']*'))
  # def step(state, {:call, address}) do

  # end
  # def step(state, :return) do

  # end
  # def step(state, :set) do

  # end
  # def step(state, {:branch, address}) do

  # end
  # def step(state, {:branch_true, address}) do

  # end
  # def step(state, {:branch_false, address}) do

  # end
  # def step(state, :branch_error) do

  # end
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
end
