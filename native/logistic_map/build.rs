extern crate gcc;

fn main() {
    gcc::Build::new()
                .file("src/c/logimap.c")
                .include("src")
                .include("/usr/local/lib/erlang/erts-9.2/include/")
                .compile("liblogimap.a");
}