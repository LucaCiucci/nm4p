# nm4p
 Numerical Methods for Physics (course code)

Some code I wrote for the course of Numerical Methods for Physics at the University of Pisa.

## Project structure

- `mod_*`: a folder for each module of the course I worked on
- `utils`: a folder containing some useful code that is not related to a specific module
- `book`: a folder containing some comments

Note that there might be cross dependencies between modules.

## Running the code

If you [installed Rust](https://www.rust-lang.org/tools/install), you can navigate to any module folder and run an example. In VSCode, you can also use the `Run` button above the main function of each example.

Example:
```sh
# update Rust if needed with `rustup update`
cd mod_0
cargo run --example congruent_generator # add --release if too slow
```

Some examples might need a minute or two to build because of external dependencies.

## Reading the book

```sh
# install mdbook if needed with `cargo install mdbook`
cd book
mdbook serve --open
```