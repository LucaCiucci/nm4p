use ../nu-utils.nu run-example

# Runs all the tasks in the file
export def "main" [] {
    main run primo_test_metrogauss
    main run primo_test_metrogauss-skip
    main run metrogauss-low-delta
    main run metrogauss-high-delta
    main run metrogauss-acceptance
    main run primo_test_metrogauss

    main run metrogauss-acceptance

    main run autocorr_plain
    main run autocorr_plain-log
    main run autocorr_plain-full
    main run autocorr_fft-full

    main run autocorr_fft-typical

    main run autocorr-int
    main run autocorr-int-full
    main run autocorr-int-full-corrected

    main run autocorr-int-algo
    main run autocorr-int-algo-deriv

    main run autocorr-int-finder-tau_int-vs-iter

    main run metrogauss-tau_vs_acc

    main run binning
    main run binning-comparison

    main run reweighting-failure

    print $"(ansi blue)mod_1(ansi reset) (ansi green)Done!(ansi reset)"
}

def "main run primo_test_metrogauss" [] {
    run-example metropolis-gauss [
        1000
        --seed 42
        --mu 10
        --sigma 1
        --x0 0
        --delta 1
        --plot mod_1/img/plots/primo_test_metrogauss
    ]
}

def "main run primo_test_metrogauss-skip" [] {
    run-example metropolis-gauss [
        1000
        --seed 42
        --mu 10
        --sigma 1
        --x0 0
        --delta 1
        --plot mod_1/img/plots/primo_test_metrogauss-skip
        --skip 1000000
    ]
}

def "main run metrogauss-low-delta" [] {
    run-example metropolis-gauss [
        100
        --seed 42
        --mu 10
        --sigma 1
        --x0 0
        --delta 0.1
        --plot mod_1/img/plots/metrogauss-low-delta
        --skip 1000000
        --print-stats
    ]
}

def "main run metrogauss-high-delta" [] {
    run-example metropolis-gauss [
        100 --seed 42
        --mu 10
        --sigma 1
        --x0 0
        --delta 50
        --plot mod_1/img/plots/metrogauss-high-delta
        --skip 1000000
        --print-stats
    ]
}

def "main run metrogauss-acceptance" [] {
    run-example metropolis-gauss-acc-plot --release []
}

def "main run autocorr_plain" [] {
    run-example autocorr-plain --release [
        10000000
        200
        mod_1/img/plots/autocorr_plain
    ]
}

def "main run autocorr_plain-log" [] {
    run-example autocorr-plain --release [
        10000000
        200
        mod_1/img/plots/autocorr_plain-log
        --y-log
    ]
}

def "main run autocorr_plain-full" [] {
    run-example autocorr-plain --release [
        1000
        1000
        mod_1/img/plots/autocorr_plain-full
    ]
}

def "main run autocorr_fft-full" [] {
    run-example autocorr-fft [
        1000
        1000
        mod_1/img/plots/autocorr_fft-full
    ]
}

def "main run autocorr_fft-typical" [] {
    run-example autocorr-fft [
        10000
        300
        mod_1/img/plots/autocorr_fft-typical
    ]
}

def "main run autocorr-int" [] {
    run-example autocorr-int [
        10000
        200
        mod_1/img/plots/autocorr-int
    ]
}

def "main run autocorr-int-full" [] {
    run-example autocorr-int [
        1000
        1000
        mod_1/img/plots/autocorr-int-full
    ]
}

def "main run autocorr-int-full-corrected" [] {
    run-example autocorr-int [
        1000
        1000
        mod_1/img/plots/autocorr-int-full-corrected
        --corrected
    ]
}

def "main run autocorr-int-algo" [] {
    run-example autocorr-int-finder [
        10000
        300
        mod_1/img/plots/autocorr-int-algo
    ]
}

def "main run autocorr-int-algo-deriv" [] {
    run-example autocorr-int-finder [
        10000
        300
        mod_1/img/plots/autocorr-int-algo-deriv
        --on-derivative
    ]
}

def "main run autocorr-int-finder-tau_int-vs-iter" [] {
    run-example autocorr-int-finder-comparison --release []
}

def "main run metrogauss-tau_vs_acc" [] {
    run-example metropolis-gauss-tau-vs-acc --release []
}

def "main run binning" [] {
    run-example binning --release [
        binning
        --tau 5
        -n 100000
        --repetitions 1000
        --k-max 10000
        --subdivisions 50
    ]
}

def "main run binning-comparison" [] {
    run-example binning --release [
        binning-comparison
        --tau 5
        -n 100000
        --repetitions 1000
        --k-max 10000
        --subdivisions 50
        --comparison
    ]
}

def "main run reweighting-failure" [] {
    run-example reweighting-failure []
}