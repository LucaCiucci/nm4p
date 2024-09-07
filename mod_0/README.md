# Congruent Random Number Generator

This is a simple port of the [original code](./fortran_src/congruent_random_number_generator.f) written in Fortran by [Massimo D'elia](https://sites.google.com/a/unipi.it/pisa-theory-group/people/delia-massimo). The rust code is in the [src/congruent_random_number_generator.rs](./src/congruent_random_number_generator.rs) module.

You can run the [example](examples/congruent_random_number_generator.rs) with the following command:

```sh
cargo run --example congruent_random_number_generator
cargo run --example run
```

You can also use this code as a dependency in your project by adding the following line to your `Cargo.toml` file:

```toml
[dependencies]
codici_mod_0 = { path = "path/to/this/folder" }
```