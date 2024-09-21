#import "styles.typ": common-styles
#import "common.typ": *

#show: common-styles

#set text(lang: "it")

= Ciao

ciao

#note[
  Ciao
]

```rs
fn ciao() {
    println!("ciao");
}
```

#outline()

#pagebreak()

#include "mod_1/mod.typ"