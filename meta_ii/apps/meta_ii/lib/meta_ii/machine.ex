defmodule MetaII.Machine do

  def step(state) do
    case read_current_op(state) do
      {:ok, op} -> state |> step(op) |> step
      error -> error
    end
  end
  def step(state, {:test, str}) do
    input = state[:input] |> String.trim_leading

    if String.starts_with?(input, str) do
      prefix_len = byte_size(str)
      <<_::binary-size(prefix_len), new_input::binary>> = input

      state
      |> update(:input, new_input)
      |> update(:switch, true)
    else
      state
      |> update(:switch, false)
    end
  end
  def step(state, :identifier) do

  end
  def step(state, :number) do

  end
  def step(state, :string) do

  end
  def step(state, {:call, address}) do

  end
  def step(state, :return) do

  end
  def step(state, :set) do

  end
  def step(state, {:branch, address}) do

  end
  def step(state, {:branch_true, address}) do

  end
  def step(state, {:branch_false, address}) do

  end
  def step(state, :branch_error) do

  end
  def step(state, {:copy_literal, str}) do

  end
  def step(state, :copy_input) do

  end
  def step(state, :generate1) do

  end
  def step(state, :generate2) do

  end
  def step(state, :label) do

  end
  def step(state, :output) do

  end
  def step(state, {:address, ident}) do

  end
  def step(state, :end) do

  end
  def step(state, op) do
    {:error, "Unrecognized op #{inspect op}"}
  end

  defp read_current_op(state) do
    {:error, "TODO: read current op from PC"}
  end

  defp update(state, key, val), do: Map.put(state, key, val)
end
