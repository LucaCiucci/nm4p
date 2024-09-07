use nu-utils.nu [find-references check-references]

use ./mod_0/mod_0.nu
use ./mod_1/mod_1.nu

# Runs all the tasks and generates the report PDF
export def main [] {
    main run all
    main compile report
}

# Run all modules tasks
def "main run all" [] {
    print $"(ansi green)################################################################(ansi reset)"
    print $"(ansi green)                   RUNNING ALL MODULES TASKS                    (ansi reset)"
    print $"(ansi green)################################################################(ansi reset)"

    print ""
    print $"(ansi green)################################(ansi reset)"
    print $"(ansi blue)            MOD 0               (ansi reset)"
    print $"(ansi green)################################(ansi reset)"
    mod_0

    print ""
    print $"(ansi green)################################(ansi reset)"
    print $"(ansi blue)            MOD 1               (ansi reset)"
    print $"(ansi green)################################(ansi reset)"
    mod_1

    print $"(ansi green)################################################################(ansi reset)"
    print $"(ansi green)                              DONE!                             (ansi reset)"
    print $"(ansi green)################################################################(ansi reset)"
}

# Compile the report PDF
def "main compile report" [] {
    #main references
    #main check references
    print "Compiling report..."
    typst compile report.typ
    print "Report compiled"
}

# Show all references and where they are used
def "main references" [] {
    print "Reference usage:"
    find-references mod_1/bibliography.yaml **/*.typ | table --expand | print
}

# Check that all references are used
def "main check references" [] {
    check-references mod_1/bibliography.yaml **/*.typ
}