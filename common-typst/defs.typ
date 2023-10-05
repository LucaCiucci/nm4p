
#import "common/boxes.typ": *
#import "common/common_styles.typ": *
#import "common/project.typ": *

#let code_ref(file, line: 0) = {
    let base = "https://github.com/LucaCiucci/nm4p/tree/rust/";
    let content = if line <= 0 {
        file
    } else {
        file + ":" + str(line)
    };
    link(base + file, raw(content, block: false))
}