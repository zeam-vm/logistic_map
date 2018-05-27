extern crate gcc;

fn main() {
    gcc::Build::new()
                .file("src/c/logimap.c")
                .include("src")
                .compile("liblogimap.a");
}