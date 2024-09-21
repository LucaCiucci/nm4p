set shell := ["nu", "-c"]

default:
    @just --list

build:
    @cargo build --workspace

test:
    @cargo test --workspace

# run a binary in the workspace
run BIN *ARGS:
    @cargo run --quiet --bin {{ BIN }} -- {{ ARGS }}
