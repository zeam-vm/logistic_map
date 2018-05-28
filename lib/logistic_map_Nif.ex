defmodule LogisticMapNif do
  use Rustler, otp_app: :logistic_map, crate: :logistic_map

  # When your NIF is loaded, it will override this function.
  def call_ocl(_x, _p, _mu), do: :erlang.nif_error(:nif_not_loaded)

  def calc(_x, _p, _mu), do: :erlang.nif_error(:nif_not_loaded)

  def map_calc_list(_list, _num, _p, _mu), do: :erlang.nif_error(:nif_not_loaded)

  def to_binary(_list), do: 
  :erlang.nif_error(:nif_not_loaded)

  def map_calc_binary(_binary, _num, _p, _mu), do:
  :erlang.nif_error(:nif_not_loaded)

  def floor(value, precision \\ 1) do
    Float.floor(value / precision) * precision |> Kernel.trunc
  end

  def get_env(key) do
  	System.get_env(key) |> String.to_integer
  end

  def put_env(key, value) do
  	System.put_env(key, "#{value}")
  	"#{key}: #{value}\n"
  end

  def env_floor(key) do
  	  System.put_env(key, "#{Kernel.max(1, floor(get_env(key), 100))}")
  end

  def calibration(key, function, is_map_calc, length \\ 10) do
    input = 1..length |> Enum.to_list
	  {micro, _} = :timer.tc(fn -> function.(input) end)
  	ms = micro |> Kernel./(1000)
  	if ms >= 1 do
  		env_floor key
  		get_env key
  	else
  	  put_env(key, length)
  	  calibration(key, function, is_map_calc, length + 10)
  	end
	end

	def min_calibration(keywords, number \\ 10) do
	  key = keywords[:key]
	  function = keywords[:function]
	  is_map_calc = keywords[:is_map_calc]
    put_env(key, 1)
		value = 1..number
		|> Enum.map(fn _ -> calibration(key, function, is_map_calc) end)
		|> Enum.min
		put_env(key, value)
	end

  def init do
  	[[key: "LogisticMapNif_map_calc_list", function: fn x -> map_calc_list(x, 10, 61, 22) end, is_map_calc: true],
  	 [key: "LogisticMapNif_map_calc_binary", function: fn x -> x |> Enum.reduce("", fn (x, acc) -> acc<><<x>> end) |> map_calc_binary(10, 61, 22) end, is_map_calc: true],
  	 [key: "LogisticMapNif_map_calc_binary_to_binary", function: fn x -> x |> to_binary |> map_calc_binary(10, 61, 22) end, is_map_calc: true],
     [key: "LogisticMapNif_call_ocl", function: fn x -> call_ocl(x, 61, 22) end, is_map_calc: true]]
  	|> Enum.map(& min_calibration(&1))
  	|> IO.puts
  end
end
