# LogisticMap

Benchmark of Logistic Map using integer calculation and `Flow`.

## Installation

Install rustup to install Rust tool chain according to https://rustup.rs 

It is [available in Hex](https://hex.pm/docs/publish), so the package can be installed
by adding `logistic_map` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:logistic_map, "~> 1.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/logistic_map](https://hexdocs.pm/logistic_map).

## Usage

To run all benchmarks,

```bash
$ mix run -e "LogisticMap.allbenchmarks"
```

The scores are better if it is smaller.

The benchmarks consists of as follows:

|benchmark name|description|
|:-------------|:----------|
|benchmarks1   |pure Elixir(loop)|
|benchmarks2   |pure Elixir(inlining outside of Flow.map)|
|benchmarks3   |pure Elixir(inlining inside of Flow.map)|
|benchmarks4   |pure Elixir(loop: variation)|
|benchmarks5   |Rustler loop, passing by list|
|benchmarks6   |Rustler loop, passing by binary created by Elixir|
|benchmarks7   |Rustler loop, passing by binary created by Rustler|
|benchmarks8   |Rustler loop, passing by list, with Window|


 