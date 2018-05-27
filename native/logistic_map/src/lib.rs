#[macro_use] extern crate rustler;
// #[macro_use] extern crate rustler_codegen;
#[macro_use] extern crate lazy_static;

extern crate ocl;

use rustler::{NifEnv, NifTerm, NifResult, NifEncoder, NifError};
use rustler::types::list::NifListIterator;
use rustler::types::binary::{ NifBinary };
use std::mem;
use std::slice;
use std::str;

use ocl::ProQue;

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
     ("call_ocl", 0, call_ocl)],
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

fn to_binary<'a>(env: NifEnv<'a>, args: &[NifTerm<'a>]) -> NifResult<NifTerm<'a>> {
    let iter: NifListIterator = try!(args[0].decode());
    let res: Result<Vec<i64>, NifError> = iter
        .map(|x| x.decode::<i64>())
        .collect();
    match res {
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

fn map_calc_binary<'a>(env: NifEnv<'a>, args: &[NifTerm<'a>]) -> NifResult<NifTerm<'a>> {
    let in_binary : NifBinary = args[0].decode()?;
    let num: i64 = try!(args[1].decode());
    let p: i64 = try!(args[2].decode());
    let mu: i64 = try!(args[3].decode());

    let res = in_binary.iter().map(|&s| s as i64).map(|x| loop_calc(num, x, p, mu)).collect::<Vec<i64>>();
    Ok(res.encode(env))
}

fn trivial() -> ocl::Result<()> {
    let src = r#"
        __kernel void add(__global float* buffer, float scalar) {
            buffer[get_global_id(0)] += scalar;
        }
    "#;

    let pro_que = ProQue::builder()
        .src(src)
        .dims(1 << 20)
        .build()?;

    let buffer = pro_que.create_buffer::<f32>()?;

    let kernel = pro_que.kernel_builder("add")
        .arg(&buffer)
        .arg(10.0f32)
        .build()?;

    unsafe { kernel.enq()?; }

    let mut vec = vec![0.0f32; buffer.len()];
    buffer.read(&mut vec).enq()?;

    println!("The value at index[{}] is now '{}'!", 200007, vec[200007]);
    Ok(())
}

fn call_ocl<'a>(env: NifEnv<'a>, _args: &[NifTerm<'a>]) -> NifResult<NifTerm<'a>> {
    let _res = trivial();
    Ok((atoms::ok()).encode(env))
}