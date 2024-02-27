
#import "common/boxes.typ": *
#import "common/common_styles.typ": *
#import "common/project.typ": *
#import "common/ieee.typ": *

#let code_ref(file, line: -1) = {
    let url = "https://github.com/LucaCiucci/nm4p/tree/main" + file;
    let line = if type(line) == "string" {
        let file = read(file);
        let line = file.split("\n").enumerate().find((nl) => nl.at(1).contains(line));
        if line == none {
            panic("line not found")
        }
        line.at(0) + 1
    } else {
        line
    }
    let content = if line < 0 {
        file
    } else {
        url = url + "#L" + str(line);
        file + ":" + str(line)
    };
    link(url, raw(content, block: false))
    footnote(link(url, url))
}

#let typ_label = label
#let appendix(title, body, render: (it, label) => it, label: "") = {
    let h = heading([Appendix: #title], supplement: "Appendix");
    if label != "" {
        [#h #typ_label(label)]
    } else {
        h
    }
    render(body, label)
}

#let round_with_err(x, err) = {
    let n-digits = -calc.ceil(calc.log(err)) + 1;
    let multiplier = calc.pow(10, n-digits);
    let round(x) = calc.round(x * multiplier) / multiplier;
    let x = round(x);
    let err = round(err);
    (x, err)
}

#let format_with_err(x, err) = {
    let (x, err) = round_with_err(x, err);
    $#x plus.minus #err$
}

#let mod_1-command = (command) => raw("nu mod_1/tasks.nu " + command, block: false, lang: "sh")