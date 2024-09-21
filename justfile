set shell := ["nu", "-c"]

default:
    just --list

build:
    @cargo build --workspace

hello:
    @cargo run --quiet --bin hello

test:
    @cargo test --workspace

run BIN *ARGS:
    cargo run --quiet -p mod_1 --bin {{ BIN }} -- {{ ARGS }}
