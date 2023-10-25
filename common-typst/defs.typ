
#import "common/boxes.typ": *
#import "common/common_styles.typ": *
#import "common/project.typ": *
#import "common/ieee.typ": *

#let code_ref(file, line: 0) = {
    let url = "https://github.com/LucaCiucci/nm4p/tree/rust/" + file;
    let content = if line <= 0 {
        file
    } else {
        url = url + "#L" + str(line);
        file + ":" + str(line)
    };
    link(url, raw(content, block: false))
    footnote(link(url, url))
}

#let appendix(title) = heading([Appendix: #title], supplement: "Appendix")

#let round_with_err(x, err) = {
    let n-digits = -calc.ceil(calc.log(err)) + 1;
    let multiplier = calc.pow(10, n-digits);
    //let x = calc.round(x 
    let round(x) = calc.round(x * multiplier) / multiplier;
    let x = round(x);
    let err = round(err);
    (x, err)
}

#let format_with_err(x, err) = {
    let (x, err) = round_with_err(x, err);
    $#x plus.minus #err$
}