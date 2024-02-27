# nm4p
 Numerical Methods for Physics (course code)

Some code I wrote for the course of Numerical Methods for Physics at the University of Pisa.

## Project structure

- `mod_*`: a folder for each module of the course I worked on
- `utils`: a folder containing some useful code that is not related to a specific module
- `book`: a folder containing some comments

Note that there might be cross dependencies between modules.

## Running the code

> ⚠️ **Warning**: at the time of write, [`cargo-script`](https://rust-lang.github.io/rfcs/3424-cargo-script.html) is still unstable, it would work with nightly Rust but there is no rust-analyzer support for it. For this reason, all the script are just examples in the `examples` folder of each module.

### Requirements
<!-- cargo install --git https://github.com/typst/typst --tag v0.10.0 -->
1. [Rust installation](https://www.rust-lang.org/tools/install)
2. [Nushell](https://www.nushell.sh/) you (`cargo install nu`)
3. If you also want to build the report PDF, you need a [Typst](https://github.com/typst/typst) installation (at the time of write, you can install it with `cargo install --git https://github.com/typst/typst --rev 09b364e typst-cli`)

### Running tasks

Individual examples can be run with arbitrary parameters with:
```sh
cargo run --example <example_name> [--release] [args...]
```

The [`tasks.nu`](tasks.nu) script contains all the commands to generate the data and figures used in the report (takes **a lot** of time to run):
```sh
nu tasks.nu
```

You can also run individual tasks with (for example):
```sh
nu mod_1/tasks.nu run primo_test_metrogauss
```

The scripts also provide some subcommands, for example, to compile the report:
```sh
nu tasks.nu compile report
```