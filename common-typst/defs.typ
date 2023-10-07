
#import "common/boxes.typ": *
#import "common/common_styles.typ": *
#import "common/project.typ": *

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

#let appendix(title) = heading(title, supplement: "Appendix")