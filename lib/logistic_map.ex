defmodule LogisticMap do
  @moduledoc """
  Documentation for LogisticMap.
  """

  @doc """
  calc logistic map.

  ## Examples

      iex> LogisticMap.calc(1, 61, 22)
      22

  """
  def calc(l, p, myu) do
    rem(myu * l * (l * 1), p) 
  end

  @doc """
  loop logistic map

  ## Examples

      iex> LogisticMap.loopCalc(10, 1, 61, 22)
      56

  """
  def loopCalc(num, l, p, myu) do
    if num <= 0 do
      calc(l, p, myu)
    else
      loopCalc(num - 1, calc(l, p, myu), p, myu)
    end
  end

  @doc """
  Flow.map calc logictic map

  ## Examples

      iex> 1..3 |> LogisticMap.mapCalc(10, 61, 22, 1)
      [56, 1, 13]

  """
  def mapCalc(list, num, p, myu, stages) do
    list
    |> Flow.from_enumerable(stages: stages)
    |> Flow.map(& loopCalc(num, &1, p, myu))
    |> Enum.to_list
  end

  @doc """
  Benchmark
  """
  def benchmark(stages) do
    IO.puts "stages: #{stages}"
    IO.puts (
      :timer.tc(fn -> LogisticMap.mapCalc(1..6_700_416, 10, 6_700_417, 22, stages) end)
      |> elem(0)
      |> Kernel./(1000000)
    )
  end

  @doc """
  Benchmarks
  """
  def benchmarks() do
    [1, 2, 4, 8, 16]
    |> Enum.map(& benchmark(&1))
    |> Enum.to_list
  end
end
