defmodule LogisticMap do
  @moduledoc """
  Documentation for LogisticMap.
  """

  @doc """
  calc logistic map.

  ## Examples

      iex> LogisticMap.calc(1, 61, 22)
      44

  """
  def calc(x, p, mu) do
    rem(mu * x * (x + 1), p) 
  end

  @doc """
  loop logistic map

  ## Examples

      iex> LogisticMap.loopCalc(10, 1, 61, 22)
      52

  """
  def loopCalc(num, x, p, mu) do
    if num <= 0 do
      calc(x, p, mu)
    else
      loopCalc(num - 1, calc(x, p, mu), p, mu)
    end
  end

  @doc """
  Flow.map calc logictic map

  ## Examples

      iex> 1..3 |> LogisticMap.mapCalc(10, 61, 22, 1)
      [52, 26, 5]

  """
  def mapCalc(list, num, p, mu, stages) do
    list
    |> Flow.from_enumerable(stages: stages)
    |> Flow.map(& loopCalc(num, &1, p, mu))
    |> Enum.to_list
  end

  @doc """
  Benchmark
  """
  def benchmark(stages) do
    IO.puts "stages: #{stages}"
    IO.puts (
      :timer.tc(fn -> mapCalc(1..0x2000000, 10, 6_700_417, 22, stages) end)
      |> elem(0)
      |> Kernel./(1000000)
    )
  end

  @doc """
  Benchmarks
  """
  def benchmarks() do
    [1, 2, 4, 8, 16, 32, 64, 128]
    |> Enum.map(& benchmark(&1))
    |> Enum.to_list
  end
end
