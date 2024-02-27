use std assert

# Runs the example with the given name and arguments
export def run-example [
    name: string # Name of the example to run
    args: list<string> # Arguments to pass to the example
    --release # Run the example in release mode
] {
    print $"running example (ansi blue)($name)(ansi reset)..."
    if $release {
        cargo run --example $name --release -- ...$args
    } else {
        cargo run --example $name -- ...$args
    }
}

# Find all the references usage
export def find-references [
    bibliography: string # Path to the bibliography file
    file_selector: string # Selector for the files to check
] {
    let files = ls $file_selector | select name
    let files = $files.name

    let bib = cat $bibliography | from yaml
    let cols = $bib | columns

    mut references = {}
    for col in $cols {
        $references = { ...$references, $col: [] }
    }

    for file in $files {
        let source = cat $file
        for col in $cols {
            let ref_tag = $"@($col)"
            let found = ($source | str index-of $ref_tag) > 0
            if $found {
                let r = $references | get $col
                # $references = { ...$references, $col: [ $r $file ] }
                #$references = $references | insert $col ($r | append $file)
                $references = ($references | merge {$col: ($r | append $file)})
            }
        }
    }

    $references
}

# Check that all the references are used
export def check-references [
    bibliography: string # Path to the bibliography file
    file_selector: string # Selector for the files to check
] {
    let refs = find-references $bibliography $file_selector
    let cols = $refs | columns
    mut not_referenced = []
    for col in $cols {
        let r = $refs | get $col
        if ($r | is-empty) {
            $not_referenced = ($not_referenced | append $col)
        }
    }
    assert ($not_referenced == []) $"unused references: ($not_referenced)"
}