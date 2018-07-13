#[macro_use] extern crate rustler;
// #[macro_use] extern crate rustler_codegen;
#[macro_use] extern crate lazy_static;

extern crate ocl;
extern crate rayon;
extern crate scoped_pool;

use rustler::{Env, Term, NifResult, Encoder, Error};
use rustler::env::{OwnedEnv, SavedTerm};
use rustler::types::list::ListIterator;
use rustler::types::map::MapIterator;
use rustler::types::binary::Binary;

use rustler::types::tuple::make_tuple;
use std::mem;
use std::slice;
use std::str;
use std::ops::RangeInclusive;

use rayon::prelude::*;
use rayon::ThreadPool;

use ocl::{ProQue, Buffer, MemFlags};

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
     ("to_binary", 1, to_binary),
     ("map_calc_binary", 4, map_calc_binary),
     ("call_empty", 3, call_empty),
//     ("call_ocl", 3, call_ocl, NifScheduleFlags::DirtyCpu)],
     ("call_ocl", 3, call_ocl),
     ("call_ocl2", 3, call_ocl2),
     ("map_calc_t1", 4, map_calc_t1)],
    None
}

lazy_static! {
    static ref POOL:scoped_pool::Pool = scoped_pool::Pool::new(8);
}

lazy_static! {
    static ref _THREAD_POOL: ThreadPool = rayon::ThreadPoolBuilder::new().num_threads(32).build().unwrap();
}

fn to_range(arg: Term) -> Result<RangeInclusive<i64>, Error> {
    let vec:Vec<(Term, Term)> = arg.decode::<MapIterator>()?.collect();
    match (&*vec[0].0.atom_to_string()?, &*vec[0].1.atom_to_string()?) {
        ("__struct__", "Elixir.Range") => {
            let first = vec[1].1.decode::<i64>()?;
            let last = vec[2].1.decode::<i64>()?;
            Ok(first ..= last)
        },
        _ => Err(Error::BadArg),
    }
}

fn to_list(arg: Term) -> Result<Vec<i64>, Error> {
    match arg.is_map() {
        true => Ok(to_range(arg)?.collect::<Vec<i64>>()),
        false => match arg.is_list() {
            true => {
                let iter: ListIterator = try!(arg.decode());
                let res: Result<Vec<i64>, Error> = iter
                    .map(|x| x.decode::<i64>())
                    .collect();

                match res {
                    Ok(result) => Ok(result),
                    Err(_) => Err(Error::BadArg)
                }
            },
            false => Err(Error::BadArg)
        },
    }
}

fn calc<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
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

fn map_calc_list<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let num: i64 = try!(args[1].decode());
    let p: i64 = try!(args[2].decode());
    let mu: i64 = try!(args[3].decode());
    match to_list(args[0]) {
        Ok(list) => Ok(list.iter().map(|&x| loop_calc(num, x, p, mu)).collect::<Vec<i64>>().encode(env)),
        Err(err) => Err(err),
    }
}

fn to_binary<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    match to_list(args[0]) {
        Ok(result) => Ok(result.iter().map(|i| unsafe {
            let ip: *const i64 = i;
            let bp: *const u8 = ip as *const _;
            let _bs: &[u8] = {
                slice::from_raw_parts(bp, mem::size_of::<i64>())
            };
            *bp
        }).collect::<Vec<u8>>()
        .iter().map(|&s| s as char).collect::<String>()
        .encode(env)),
        Err(err) => Err(err),
    }
}

fn map_calc_binary<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let in_binary : Binary = args[0].decode()?;
    let num: i64 = try!(args[1].decode());
    let p: i64 = try!(args[2].decode());
    let mu: i64 = try!(args[3].decode());

    let res = in_binary.iter().map(|&s| s as i64).map(|x| loop_calc(num, x, p, mu)).collect::<Vec<i64>>();
    Ok(res.encode(env))
}

fn trivial(x: Vec<i64>, p: i64, mu: i64) -> ocl::Result<(Vec<i64>)> {
    let src = r#"
        __kernel void calc(__global long* input, __global long* output, long p, long mu) {
            size_t i = get_global_id(0);
            long x = input[i];
            x = mu * x * (x + 1) % p;
            x = mu * x * (x + 1) % p;
            x = mu * x * (x + 1) % p;
            x = mu * x * (x + 1) % p;
            x = mu * x * (x + 1) % p;
            x = mu * x * (x + 1) % p;
            x = mu * x * (x + 1) % p;
            x = mu * x * (x + 1) % p;
            x = mu * x * (x + 1) % p;
            x = mu * x * (x + 1) % p;
            output[i] = x;
        }
    "#;

    let pro_que = ProQue::builder()
        .src(src)
        .dims(x.len())
        .build().expect("Build ProQue");

    let source_buffer = Buffer::builder()
        .queue(pro_que.queue().clone())
        .flags(MemFlags::new().read_write())
        .len(x.len())
        .copy_host_slice(&x)
        .build()?;

    let result_buffer: Buffer<i64> = Buffer::builder()
        .queue(pro_que.queue().clone())
        .flags(MemFlags::new().read_write())
        .len(x.len())
        .build()?;

    let kernel = pro_que.kernel_builder("calc")
        .arg(&source_buffer)
        .arg(&result_buffer)
        .arg(p)
        .arg(mu)
        .build()?;

    unsafe { kernel.enq()?; }

    let mut vec_result = vec![0; result_buffer.len()];
    result_buffer.read(&mut vec_result).enq()?;
    Ok(vec_result)
}

fn call_ocl<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let p: i64 = try!(args[1].decode());
    let mu: i64 = try!(args[2].decode());

    match to_list(args[0]) {
        Ok(result) => {
            let r1: ocl::Result<(Vec<i64>)> = trivial(result, p, mu);
            match r1 {
               Ok(r2) => Ok(r2.encode(env)),
               Err(_) => Err(Error::BadArg),
            }
        },
        Err(err) => Err(err),
    }
}

fn call_ocl2<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let pid = env.pid();
    let mut my_env = OwnedEnv::new();

    let saved_list = my_env.run(|env| -> NifResult<SavedTerm> {
        let list_arg = args[0].in_env(env);
        let p        = args[1].in_env(env);
        let mu       = args[2].in_env(env);
        Ok(my_env.save(make_tuple(env, &[list_arg, p, mu])))
    })?;

    POOL.spawn(move || {
        my_env.send_and_clear(&pid, |env| {
            let result: NifResult<Term> = (|| {
                let tuple = saved_list.load(env).decode::<(Term, i64, i64)>()?;
                let p = tuple.1;
                let mu = tuple.2;
                match to_list(tuple.0) {
                    Ok(result) => {
                        let r1: ocl::Result<(Vec<i64>)> = trivial(result, p, mu);
                        match r1 {
                            Ok(r2) => Ok(r2.encode(env)),
                            Err(_) => Err(Error::BadArg),
                        }
                    },
                    Err(err) => Err(err)
                }
            })();
            match result {
                Err(_err) => env.error_tuple("test failed".encode(env)),
                Ok(term) => term
            }
        });
    });
    Ok(atoms::ok().to_term(env))
}

fn call_empty<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let _p: i64 = try!(args[1].decode());
    let _mu: i64 = try!(args[2].decode());

    match to_list(args[0]) {
        Ok(result) => Ok(result.iter().map(|&x| x).collect::<Vec<i64>>().encode(env)),
        Err(err) => Err(err),
    }
}

fn map_calc_t1<'a>(env: Env<'a>, args: &[Term<'a>]) -> NifResult<Term<'a>> {
    let pid = env.pid();
    let mut my_env = OwnedEnv::new();

    let saved_list = my_env.run(|env| -> NifResult<SavedTerm> {
        let list_arg = args[0].in_env(env);
        let num      = args[1].in_env(env);
        let p        = args[2].in_env(env);
        let mu       = args[3].in_env(env);
        Ok(my_env.save(make_tuple(env, &[list_arg, num, p, mu])))
    })?;

    POOL.spawn(move || {
        my_env.send_and_clear(&pid, |env| {
            let result: NifResult<Term> = (|| {
                let tuple = saved_list.load(env).decode::<(Term, i64, i64, i64)>()?;
                let num = tuple.1;
                let p = tuple.2;
                let mu = tuple.3;

                match to_list(tuple.0) {
                    Ok(result) => Ok(result.par_iter().map(|&x| loop_calc(num, x, p, mu)).collect::<Vec<i64>>().encode(env)),
                    Err(err) => Err(err)
                }
            })();
            match result {
                Err(_err) => env.error_tuple("test failed".encode(env)),
                Ok(term) => term
            }
        });
    });
    Ok(atoms::ok().to_term(env))
}
