#[macro_use] extern crate rustler;
// #[macro_use] extern crate rustler_codegen;
#[macro_use] extern crate lazy_static;

use rustler::{NifEnv, NifTerm, NifResult, NifEncoder, NifError};
use rustler::types::list::NifListIterator;
use rustler::types::binary::{ NifBinary };

mod atoms {
    rustler_atoms! {
        atom ok;
        //atom error;
        //atom __true__ = "true";
        //atom __false__ = "false";
    }
}

rustler_export_nifs! {
    "Elixir.LogisticMapNif",
    [("calc", 3, calc),
     ("map_calc_list", 4, map_calc_list),
     ("map_calc_binary", 4, map_calc_binary)],
    None
}

fn calc<'a>(env: NifEnv<'a>, args: &[NifTerm<'a>]) -> NifResult<NifTerm<'a>> {
    let x: i64 = try!(args[0].decode());
    let p: i64 = try!(args[1].decode());
    let mu: i64 = try!(args[2].decode());

    Ok((atoms::ok(), mu * x * (x + 1) % p).encode(env))
}

fn loop_calc(num: i64, init: i64, p: i64, mu: i64) -> i64 {
    let mut x: i64 = init;
    for _i in 0..num {
        x = mu * x * (x + 1) % p;
    }
    x
}

fn map_calc_list<'a>(env: NifEnv<'a>, args: &[NifTerm<'a>]) -> NifResult<NifTerm<'a>> {
    let iter: NifListIterator = try!(args[0].decode());
    let num: i64 = try!(args[1].decode());
    let p: i64 = try!(args[2].decode());
    let mu: i64 = try!(args[3].decode());

    let res: Result<Vec<i64>, NifError> = iter
        .map(|x| x.decode::<i64>())
        .collect();

    match res {
        Ok(result) => Ok(result.iter().map(|&x| loop_calc(num, x, p, mu)).collect::<Vec<i64>>().encode(env)),
        Err(err) => Err(err),
    }
}

fn map_calc_binary<'a>(env: NifEnv<'a>, args: &[NifTerm<'a>]) -> NifResult<NifTerm<'a>> {
    let in_binary : NifBinary = args[0].decode()?;
    let num: i64 = try!(args[1].decode());
    let p: i64 = try!(args[2].decode());
    let mu: i64 = try!(args[3].decode());

    let res = in_binary.iter().map(|&s| s as i64).map(|x| loop_calc(num, x, p, mu)).collect::<Vec<i64>>();

    Ok(res.encode(env))
}