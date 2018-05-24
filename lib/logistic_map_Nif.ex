defmodule LogisticMapNif do
  use Rustler, otp_app: :logistic_map, crate: :logistic_map

  # When your NIF is loaded, it will override this function.
  def calc(_x, _p, _mu), do: :erlang.nif_error(:nif_not_loaded)

  def map_calc_list(_list, _num, _p, _mu), do: :erlang.nif_error(:nif_not_loaded)

  def to_binary(_list), do: 
  :erlang.nif_error(:nif_not_loaded)

  def map_calc_binary(_binary, _num, _p, _mu), do:
  :erlang.nif_error(:nif_not_loaded)
end
