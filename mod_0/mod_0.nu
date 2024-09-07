use ../nu-utils.nu [run-example]

export def main [] {
    run-example ran []
    run-example congruent_generator []

    print $"(ansi blue)mod_0(ansi reset) (ansi green)Done!(ansi reset)"
}