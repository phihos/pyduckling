use std::env;

fn main() {
    let dir_path = env::current_dir().unwrap();
    let path = dir_path.to_str().unwrap();
    println!("cargo:rustc-link-lib=static=ducklingffi");
    println!("cargo:rustc-link-search=native={}/ext_lib/", path);
    println!("cargo:rustc-link-lib=dylib=pcre");
    println!("cargo:rustc-link-lib=dylib=gmp");

    // Compile GHC RTS shim (provides linker symbols needed for shared libraries)
    cc::Build::new()
        .file("ext_lib/ghc_shim.c")
        .compile("ghc_shim");

    if cfg!(target_os = "macos") {
        // Homebrew on ARM64 installs to /opt/homebrew
        if let Ok(prefix) = std::process::Command::new("brew")
            .arg("--prefix")
            .output()
        {
            if let Ok(p) = std::str::from_utf8(&prefix.stdout) {
                println!("cargo:rustc-link-search=native={}/lib", p.trim());
            }
        }
        println!("cargo:rustc-link-lib=dylib=ffi");
        println!("cargo:rustc-link-lib=dylib=iconv");
        println!("cargo:rustc-link-lib=framework=CoreFoundation");
    }
}
