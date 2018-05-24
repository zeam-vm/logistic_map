defmodule LogisticMap do

  @logistic_map_size      0x2000000
  @logistic_map_chunk_num 0x400
  @default_prime 6_700_417
  @default_mu 22
  @default_loop 10


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
  calc logistic map.

  ## Examples

      iex> LogisticMap.calc2(1, 61, 22)
      44

  """
  def calc2(x, p, mu) do
    elem(LogisticMapNif.calc(x, p, mu), 1)
  end

  @doc """
  loop logistic map

  ## Examples

      iex> LogisticMap.loopCalc(10, 1, 61, 22)
      28

  """
  def loopCalc(num, x, p, mu) do
    if num <= 0 do
      x
    else
      loopCalc(num - 1, calc(x, p, mu), p, mu)
    end
  end

  @doc """
  loop logistic map

  ## Examples

      iex> LogisticMap.loopCalc2(10, 1, 61, 22)
      28

  """
  def loopCalc2(num, x, _p, _mu) when num <= 0 do x end
  def loopCalc2(num, x, p, mu) do
    new_num = num - 1
    new_calc = calc( x, p, mu )
    loopCalc2( new_num, new_calc, p, mu )
  end


  @doc """
  Flow.map calc logictic map

  ## Examples

      iex> 1..3 |> LogisticMap.mapCalc(10, 61, 22, 1)
      [28, 25, 37]

  """
  def mapCalc(list, num, p, mu, stages) do
    list
    |> Flow.from_enumerable(stages: stages)
    |> Flow.map(& loopCalc(num, &1, p, mu))
    |> Enum.to_list
  end

  @doc """
  Flow.map calc logictic map

  ## Examples

      iex> 1..3 |> LogisticMap.mapCalc2(61, 22, 1)
      [28, 25, 37]

  """
  def mapCalc2(list, p, mu, stages) do
    list
    |> Flow.from_enumerable(stages: stages)
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Flow.map(& calc(&1, p, mu))
    |> Enum.to_list
  end

  @doc """
  Flow.map calc logictic map

  ## Examples

      iex> 1..3 |> LogisticMap.mapCalc3(61, 22, 1)
      [28, 25, 37]

  """
  def mapCalc3(list, p, mu, stages) do
    list
    |> Flow.from_enumerable(stages: stages)
    |> Flow.map(& (&1
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      |> calc(p, mu)
      ))
    |> Enum.to_list
  end


  @doc """
  Flow.map calc logictic map

  ## Examples

      iex> 1..3 |> LogisticMap.mapCalc4(61, 22, 1)
      [28, 25, 37]

  """
  def mapCalc4(list, p, mu, stages) do
    list
    |> Flow.from_enumerable(stages: stages)
    |> Flow.map(& (&1
      |> calc2(p, mu)
      |> calc2(p, mu)
      |> calc2(p, mu)
      |> calc2(p, mu)
      |> calc2(p, mu)
      |> calc2(p, mu)
      |> calc2(p, mu)
      |> calc2(p, mu)
      |> calc2(p, mu)
      |> calc2(p, mu)
      ))
    |> Enum.to_list
  end

  @doc """
  Flow.map calc logictic map

  ## Examples

      iex> 1..3 |> LogisticMap.mapCalc4(10, 61, 22, 1)
      [28, 25, 37]

  """
  def mapCalc4(list, num, p, mu, stages) do
    list
    |> Flow.from_enumerable(stages: stages)
    |> Flow.map(& loopCalc2(num, &1, p, mu))
    |> Enum.to_list
  end

  @doc """
  Flow.map calc logistic map

  ## Examples

      iex> 1..3 |> LogisticMap.mapCalc5(10, 61, 22, 1)
      [28, 25, 37]
  """
  def mapCalc5(list, num, p, mu, stages) when stages <= 1 do
    list
    |> Enum.to_list
    |> LogisticMapNif.map_calc_list(num, p, mu)
  end
  def mapCalc5(list, num, p, mu, stages) when stages > 1 do
    chunk_size = div(Enum.count(list) - 1, stages) + 1
    list
    |> Stream.chunk_every(chunk_size)
    |> Flow.from_enumerable(stages: stages)
    |> Flow.map(fn(i) ->
    	i
    	|> Stream.chunk_every(@logistic_map_chunk_num)
    	|> Enum.map(fn(j) ->
    		j
    		|> LogisticMapNif.map_calc_list(num, p, mu)
    		end)
    	end)
    |> Enum.to_list
    |> List.flatten
  end


  @doc """
  Flow.map calc logistic map

  ## Examples

      iex> 1..3 |> LogisticMap.mapCalc6(10, 61, 22, 1)
      [28, 25, 37]
  """
  def mapCalc6(list, num, p, mu, stages) when stages <= 1 do
    list
    |> Enum.to_list
    |> Enum.reduce("", fn x, acc -> acc<><<x>> end)
    |> LogisticMapNif.map_calc_binary(num, p, mu)
  end
  def mapCalc6(list, num, p, mu, stages) when stages > 1 do
    chunk_size = div(Enum.count(list) - 1, stages) + 1
    list
    |> Stream.chunk_every(chunk_size)
    |> Flow.from_enumerable(stages: stages)
    |> Flow.map(fn(i) ->
      i
      |> Stream.chunk_every(@logistic_map_chunk_num)
      |> Enum.map(fn(j) ->
        j
        |> Enum.reduce("", fn (x, acc) -> acc<><<x>> end)
        |> LogisticMapNif.map_calc_binary(num, p, mu)
        end)
      end)
    |> Enum.to_list
    |> List.flatten
  end


  @doc """
  Flow.map calc logistic map

  ## Examples

      iex> 1..3 |> LogisticMap.mapCalc7(10, 61, 22, 1)
      [28, 25, 37]
  """
  def mapCalc7(list, num, p, mu, stages) when stages <= 1 do
    list
    |> Enum.to_list
    |> LogisticMapNif.to_binary
    |> LogisticMapNif.map_calc_binary(num, p, mu)
  end
  def mapCalc7(list, num, p, mu, stages) when stages > 1 do
    chunk_size = div(Enum.count(list) - 1, stages) + 1
    list
    |> Stream.chunk_every(chunk_size)
    |> Flow.from_enumerable(stages: stages)
    |> Flow.map(fn(i) ->
      i
      |> Stream.chunk_every(@logistic_map_chunk_num)
      |> Enum.map(fn(j) ->
        j
        |> LogisticMapNif.to_binary
        |> LogisticMapNif.map_calc_binary(num, p, mu)
        end)
      end)
    |> Enum.to_list
    |> List.flatten
  end

  @doc """
  Flow.map calc logistic map

  ## Examples

      iex> 1..3 |> LogisticMap.mapCalc8(10, 61, 22, 1)
      [28, 25, 37]
  """
  def mapCalc8(list, num, p, mu, stages) when stages <= 1 do
    list
    |> Enum.to_list
    |> LogisticMapNif.map_calc_list(num, p, mu)
  end
  def mapCalc8(list, num, p, mu, stages) when stages > 1 do
    window = Flow.Window.global
    |> Flow.Window.trigger_every(@logistic_map_chunk_num, :reset)

    list
    |> Flow.from_enumerable
    |> Flow.partition(window: window, stages: stages)
    |> Flow.reduce(fn -> [] end, fn e, acc -> [e | acc] end)
    |> Flow.map_state(& &1 |> LogisticMapNif.map_calc_list(num, p, mu))
    |> Flow.emit(:state)
    |> Enum.to_list
  end


  @doc """
  Benchmark
  """
  def benchmark1(stages) do
    IO.puts "stages: #{stages}"
    IO.puts (
      :timer.tc(fn -> mapCalc(1..@logistic_map_size, @default_loop, @default_prime, @default_mu, stages) end)
      |> elem(0)
      |> Kernel./(1000000)
    )
  end

  @doc """
  Benchmark
  """
  def benchmark2(stages) do
    IO.puts "stages: #{stages}"
    IO.puts (
      :timer.tc(fn -> LogisticMap.mapCalc2(1..@logistic_map_size, @default_prime, @default_mu, stages) end)
      |> elem(0)
      |> Kernel./(1000000)
    )
  end


  @doc """
  Benchmark
  """
  def benchmark3(stages) do
    IO.puts "stages: #{stages}"
    IO.puts (
      :timer.tc(fn -> LogisticMap.mapCalc3(1..@logistic_map_size, @default_prime, @default_mu, stages) end)
      |> elem(0)
      |> Kernel./(1000000)
    )
  end


  @doc """
  Benchmark
  """
  def benchmark4(stages) do
    IO.puts "stages: #{stages}"
    IO.puts (
      :timer.tc(fn -> mapCalc4(1..@logistic_map_size, @default_loop, @default_prime, @default_mu, stages) end)
      |> elem(0)
      |> Kernel./(1000000)
    )
  end

  @doc """
  Benchmark
  """
  def benchmark5(stages) do
    IO.puts "stages: #{stages}"
    IO.puts (
      :timer.tc(fn -> mapCalc5(1..@logistic_map_size, @default_loop, @default_prime, @default_mu, stages) end)
      |> elem(0)
      |> Kernel./(1000000)
    )
  end


  @doc """
  Benchmark
  """
  def benchmark6(stages) do
    IO.puts "stages: #{stages}"
    IO.puts (
      :timer.tc(fn -> mapCalc6(1..@logistic_map_size, @default_loop, @default_prime, @default_mu, stages) end)
      |> elem(0)
      |> Kernel./(1000000)
    )
  end


  @doc """
  Benchmark
  """
  def benchmark7(stages) do
    IO.puts "stages: #{stages}"
    IO.puts (
      :timer.tc(fn -> mapCalc7(1..@logistic_map_size, @default_loop, @default_prime, @default_mu, stages) end)
      |> elem(0)
      |> Kernel./(1000000)
    )
  end

  @doc """
  Benchmark
  """
  def benchmark8(stages) do
    IO.puts "stages: #{stages}"
    IO.puts (
      :timer.tc(fn -> mapCalc8(1..@logistic_map_size, @default_loop, @default_prime, @default_mu, stages) end)
      |> elem(0)
      |> Kernel./(1000000)
    )
  end

  @doc """
  Benchmarks
  """
  def benchmarks1() do
    [1, 2, 4, 8, 16, 32, 64, 128]
    |> Enum.map(& benchmark1(&1))
    |> Enum.reduce(0, fn _lst, acc -> acc end)
  end

  @doc """
  Benchmarks
  """
  def benchmarks2() do
    [1, 2, 4, 8, 16, 32, 64, 128]
    |> Enum.map(& benchmark2(&1))
    |> Enum.reduce(0, fn _lst, acc -> acc end)
  end


  @doc """
  Benchmarks
  """
  def benchmarks3() do
    [1, 2, 4, 8, 16, 32, 64, 128]
    |> Enum.map(& benchmark3(&1))
    |> Enum.reduce(0, fn _lst, acc -> acc end)
  end

  @doc """
  Benchmarks
  """
  def benchmarks4() do
    [1, 2, 4, 8, 16, 32, 64, 128]
    |> Enum.map(& benchmark4(&1))
    |> Enum.reduce(0, fn _lst, acc -> acc end)
  end


  @doc """
  Benchmarks
  """
  def benchmarks5() do
    [1, 2, 4, 8, 16, 32, 64, 128]
    |> Enum.map(& benchmark5(&1))
    |> Enum.reduce(0, fn _lst, acc -> acc end)
  end

  @doc """
  Benchmarks
  """
  def benchmarks6() do
    [1, 2, 4, 8, 16, 32, 64, 128]
    |> Enum.map(& benchmark6(&1))
    |> Enum.reduce(0, fn _lst, acc -> acc end)
  end

  @doc """
  Benchmarks
  """
  def benchmarks7() do
    [1, 2, 4, 8, 16, 32, 64, 128]
    |> Enum.map(& benchmark7(&1))
    |> Enum.reduce(0, fn _lst, acc -> acc end)
  end


  @doc """
  Benchmarks
  """
  def benchmarks8() do
    [1, 2, 4, 8, 16, 32, 64, 128]
    |> Enum.map(& benchmark8(&1))
    |> Enum.reduce(0, fn _lst, acc -> acc end)
  end

  def allbenchmarks() do
    [{&benchmarks1/0, "benchmarks1: pure Elixir(loop)"},
     {&benchmarks2/0, "benchmarks2: pure Elixir(inlining outside of Flow.map)"},
     {&benchmarks3/0, "benchmarks3: pure Elixir(inlining inside of Flow.map)"},
     {&benchmarks4/0, "benchmarks4: pure Elixir(loop: variation)"},
     {&benchmarks5/0, "benchmarks5: Rustler loop, passing by list"},
     {&benchmarks6/0, "benchmarks6: Rustler loop, passing by binary created by Elixir"},
     {&benchmarks7/0, "benchmarks7: Rustler loop, passing by binary created by Rustler"},
     {&benchmarks8/0, "benchmarks8: Rustler loop, passing by list, with Window"}]
    |> Enum.map(fn (x) ->
      IO.puts elem(x, 1)
      elem(x, 0).()
    end)
  end
end