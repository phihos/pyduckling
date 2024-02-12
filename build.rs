use std::env;

fn main() {
    let dir_path = env::current_dir().unwrap();
    let path = dir_path.to_str().unwrap();
    let ghc_version = match env::var_os("GHC_VERSION") {
        Some(v) => v.into_string().unwrap(),
        None => panic!("$GHC_VERSION is not set"),
    };
    println!("cargo:rustc-link-lib=static=ducklingffi");
    println!("cargo:rustc-link-search=native={}/ext_lib/", path);
    println!("cargo:rustc-link-lib=dylib=pcre");
    println!("cargo:rustc-link-lib=dylib=gmp");
    println!("cargo:rustc-env=GHC_VERSION={}", ghc_version);
}
