
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