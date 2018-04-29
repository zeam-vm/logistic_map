# LogisticMap

Benchmark of Logistic Map using integer caliculation and `Flow`.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `logistic_map` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:logistic_map, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/logistic_map](https://hexdocs.pm/logistic_map).

## Usage

To run benchmark,

```bash
$ mix run -e "LogisticMap.benchmarks"
```

benchmark calls calculation recursively from Flow.map.

```elixir
def loopCalc(num, x, p, mu) do
  if num <= 0 do
    x
  else
    loopCalc(num - 1, calc(x, p, mu), p, mu)
  end
end

def mapCalc(list, num, p, mu, stages) do
  list
  |> Flow.from_enumerable(stages: stages)
  |> Flow.map(& loopCalc(num, &1, p, mu))
  |> Enum.to_list
end
```

benchmarks2 and benchmarks3 are variations of benchmark.

```bash
$ mix run -e "LogisticMap.benchmarks2"
$ mix run -e "LogisticMap.benchmarks3"
```

benchmarks2 inlines `Flow.map` as follows:

```elixir
list
|> Flow.from_enumerable(stages: stages)
|> Flow.map(& calc(&1, p, mu))
|> Flow.map(& calc(&1, p, mu))
...
|> Flow.map(& calc(&1, p, mu))
|> Enum.to_list
```

benchmark3 inlines inside of `Flow.map` as folows:

```elixir
list
|> Flow.from_enumerable(stages: stages)
|> Flow.map(& (&1
  |> calc(p, mu)
  |> calc(p, mu)
...
  |> calc(p, mu)
  ))
|> Enum.to_list
```

