let here = $env.FILE_PWD

# Run metrogauss and generate a plot using 
def metrogauss [
    name: string,
    args: list<any>,
    --style: string = '.',
] {
    let plot = $here | path join $"($name).png"
    print $"Plotting (ansi light_blue)($plot)(ansi reset)"
    cargo run -q --bin metrogauss -- ...$args | python3 ($here | path join plot.py) --out $plot --style $style
}

metrogauss "high-acc" [
    -n 1000
    --seed 2
    --delta 0.2
]

metrogauss "low-acc" --style '-o' [
    -n 1000
    --seed 2
    --delta 50
]

metrogauss "med-acc" [
    -n 1000
    --seed 2
    --delta 2.0
]

metrogauss "offset" [
    -n 1000
    --x0 10.0
    --seed 2
    --delta 0.5
]