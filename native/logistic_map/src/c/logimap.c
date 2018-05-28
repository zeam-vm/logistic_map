#include <erl_nif.h>

long add_c(long x, long y) {
	return x + y;
}

static ERL_NIF_TERM add_c_2(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	ErlNifSInt64 x, y;
	if(argc == 2
	  && enif_get_int64(env, argv[0], &x)
	  && enif_get_int64(env, argv[1], &y)) {
		return enif_make_int64(env, x + y);
	} else {
		return enif_raise_exception(env, enif_make_atom(env, "insufficient_memory"));
	}
}

static ErlNifFunc nif_funcs[] = {
  // {erl_function_name, erl_function_arity, c_function}
  {"add_c", 2, add_c_2}
};

ERL_NIF_INIT(LogisticMapNif.add_c, nif_funcs, NULL, NULL, NULL, NULL)
