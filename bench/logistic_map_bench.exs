defmodule LogisticMapBench do
	use Benchfella

  LogisticMapNif.init

  @logistic_map_size      0x2000000
  @default_prime 6_700_417
  @default_mu 22
  @default_loop 10
  @range 1..@logistic_map_size

  bench "calc" do
  	LogisticMap.calc(1, @default_prime, @default_mu)
  end

  bench "calc NIF" do
  	LogisticMapNif.calc(1, @default_prime, @default_mu)
  end

  bench "Enum.map calc" do
  	@range
  	|> Enum.map(& LogisticMap.calc(&1, @default_prime, @default_mu))
  end

  bench "Flow.map calc" do
  	@range
  	|> Flow.from_enumerable
  	|> Flow.map(& LogisticMap.calc(&1, @default_prime, @default_mu))
  	|> Enum.to_list
  end

  bench "loopCalc" do
  	LogisticMap.loopCalc(@default_loop, 1, @default_prime, @default_mu)
  end

  bench "bench1: pure Elixir(loop)" do
  	@range
  	|> LogisticMap.mapCalc(@default_loop, @default_prime, @default_mu, System.schedulers_online)
  end

  bench "bench3: pure Elixir(inlining inside of Flow.map)" do
  	@range
  	|> LogisticMap.mapCalc3(@default_prime, @default_mu, System.schedulers_online)
  end

  bench "bench8_1: Rustler loop, passing by list, with Window" do
  	@range
  	|> LogisticMap.mapCalc8(@default_loop, @default_prime, @default_mu, 1)
  end

  bench "bench8_s: Rustler loop, passing by list, with Window" do
  	@range
  	|> LogisticMap.mapCalc8(@default_loop, @default_prime, @default_mu, System.schedulers_online)
  end

  bench "bench_g1: OpenCL(GPU)" do
  	@range
  	|> LogisticMap.map_calc_g1(@default_prime, @default_mu, System.schedulers_online)
  end

  bench "bench_g2: OpenCL(GPU) asynchronously" do
  	@range
  	|> LogisticMap.map_calc_g2(@default_prime, @default_mu, System.schedulers_online)
  end

  bench "bench_empty: Ruslter empty" do
  	@range
  	|> LogisticMap.mapEmpty(@default_prime, @default_mu, System.schedulers_online)
  end

  bench "bench_t1: asynchronous multi-threaded Rustler, passing by list" do
  	@range
  	|> LogisticMap.map_calc_t1(@default_loop, @default_prime, @default_mu, System.schedulers_online)
  end
end