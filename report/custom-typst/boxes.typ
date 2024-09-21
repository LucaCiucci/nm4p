
//#import "styles.typ": *

//#show: common-styles

#outline()

#let typ_label = label

= Callout

`callout` creates a box with a header and a body. It is used inside the other macros.

#let callout(
  color: gray,
  header: [],
  body
) = {
  let stroke = 2pt + color;
  let radius = 1pt;
  let inset = 1pt;
  let clip = true;

  if header == [] {
    block(
      block(body, inset: 0.5em, width: 100%),
      stroke: 2pt + color,
      radius: 1pt,
      inset: 1pt,
      clip: true,
    )
  } else {
    block(
      stack(
        box(header, fill: color.lighten(50%), inset: 0.5em, width: 100%),
        block(body, inset: 0.5em, width: 100%)
      ),
      stroke: 2pt + color,
      radius: 1pt,
      inset: 1pt,
      clip: true,
    )
  }
}

#let custom-figure(
  body-func,
  kind: "@gh:LucaCiucci99::custom-figure",
  supplement: [Custom Figure],
  label: [],
) = {
  if type(body-func) != "function" {
    panic()
  }

  show figure.where(kind: kind): f => f.counter.display()

  body-func([#figure([], kind: kind, supplement: supplement) #label])
}

#let callout-box(
  body,
  header: none,
  color: gray,
) = {
  let stroke = 2pt + color;
  let radius = 1pt;
  let inset = 1pt;
  let clip = true;

  let common-settings = (
    inset: 0pt,
    clip: true,
  );

  if header == none {
    block(
      block(body, inset: 0.5em, width: 100%),
      stroke: (left: 3pt + color),
      ..common-settings,
    )
  } else {
    block(
      stack(
        box(header, fill: color.lighten(50%), inset: 0.5em, width: 100%),
        block(body, inset: 0.5em, width: 100%)
      ),
      stroke: (
        left: 2pt + color,
        top: 1pt + color,
        right: 1pt + color,
        bottom: 1pt + color,
      ),
      radius: 3pt,
      ..common-settings,
    )
  }
}

#table(
  columns: (auto, auto),
  [
    ```typ
    #callout[lorem(10)]
    ```
  ],
  [
    #callout(lorem(10))
  ],
  [
    ```typ
    #callout(
      color: gray,
      header: lorem(5)
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #callout(
      color: gray,
      header: lorem(5)
    )[
      #lorem(10)
    ]
  ],
)

= Predefined Callouts

#let custom-callout(
  title: none,
  label: none,
  body,
  color: gray,
  header: [#sym.circle.filled #underline[*Callout*]],
  header-short: none,
  supplement: [Call],
  kind: "custom-theorem",
) = custom-figure(
  if title == none {
    n => callout-box(
      color: color,
      [#(if header-short == none { header } else { header-short }) #n: #body],
    )
  } else {
    n => callout-box(
      header: if title == [] or title == "" {
        [#header #n]
      } else {
        [#header #n: #title]
      },
      color: color,
      body,
    )
  },
  label: label,
  supplement: supplement,
  kind: kind,
)


#let note = custom-callout.with(
  //color: rgb("#2ecc40"),
  color: yellow.darken(10%),
  header: [#emoji.pencil *Note*],
  supplement: [Note],
  kind: "note",
)

#let idea = custom-callout.with(
  //color: rgb("#2ecc40"),
  color: green,
  header: [#emoji.lightbulb *Idea*],
  supplement: [idea],
  kind: "note",
)

#let example = custom-callout.with(
  color: gray,
  header: [🕮 *example*],
  supplement: [ex.],
  kind: "example",
)

#let question = custom-callout.with(
  color: rgb("#0074d9"),
  header: [🕮 *question*],
  supplement: [question],
  kind: "question",
)

#let exercise = custom-callout.with(
  color: rgb("#0074d9"),
  header: [#emoji.pencil *exercise*],
  supplement: [exercise],
  kind: "exercise",
)

#let info = custom-callout.with(
  //color: rgb("#2ecc40"),
  //color: yellow.darken(10%),
  color: rgb("#2ecc40"),
  header: [🛈 *Info*],
  supplement: [info],
  kind: "info",
)

#let todo = custom-callout.with(
  color: rgb("#ba55d3"),
  header: [#emoji.square *TODO*],
  supplement: [todo],
  kind: "todo",
)

// TODO maybe unify with todo using a "done" parameter
// this can be done by redirecting the other args (..args)
#let todo-done = custom-callout.with(
  color: rgb("#ba55d3").darken(15%).desaturate(50%),
  header: strike[#emoji.ballot.check *TODO*],
  supplement: [todo],
  kind: "todo",
)

#let proposition = custom-callout.with(
  color: rgb("#ff851b"),
  header: [#sym.square *proposition*],
  supplement: [prop.],
  kind: "theorem",
)

#let observation = custom-callout.with(
  color: rgb("#ff851b"),
  header: [#sym.square *observation*],
  supplement: [obs.],
  kind: "theorem",
)

#let theorem = custom-callout.with(
  color: red.lighten(20%),
  header: [#sym.square *theorem*],
  supplement: [thm.],
  kind: "theorem",
)

#let lemma = custom-callout.with(
  color: red.lighten(20%),
  header: [#sym.square *lemma*],
  supplement: [Lem.],
  kind: "theorem",
)

#let corollary = custom-callout.with(
  color: red.lighten(20%),
  header: [#sym.square *corollary*],
  supplement: [Cor.],
  kind: "theorem",
)

#let proof = custom-callout.with(
  color: green,
  header: [#sym.square *proof*],
  supplement: [Proof],
  kind: "theorem",
)

#let definition = custom-callout.with(
  color: rgb("#ff851b"),
  header: [#sym.square *definition*],
  supplement: [def.],
  kind: "definition",
)

#let postulate = custom-callout.with(
  color: rgb("#ff851b"),
  header: [#sym.square *postulate*],
  supplement: [post.],
  kind: "definition",
)

#let warning = custom-callout.with(
  color: orange,
  header: [#emoji.warning *Warning*],
  supplement: [Warning],
  kind: "warning",
)

#let remark = custom-callout.with(
  color: rgb("#e74c3c"),
  header: [#emoji.excl.double *remark*],
  supplement: [rem.],
  kind: "warning",
)

#let important = custom-callout.with(
  color: rgb("#e74c3c"),
  header: [#emoji.excl.double *important*],
  supplement: [rem.],
  kind: "warning",
)

#let danger = custom-callout.with(
  color: rgb("#e74c3c"),
  header: [#emoji.excl.double *danger*],
  supplement: [rem.],
  kind: "warning",
)

#let quote = custom-callout.with(
  color: rgb("#2c3e50"),
  header: [❞ *quote*],
  //header: [🕮 *quote*],
  supplement: [quote],
  kind: "quote",
)

#let algorithm = custom-callout.with(
  color: rgb("#2c3e50"),
  header: [#emoji.gear *algorithm*],
  supplement: [algo.],
  kind: "algorithm",
)

#let listing = custom-callout.with(
  color: rgb("#2c3e50"),
  header: [/*#text("</>", font: "FreeMono")*/#box(text("</>", fill: gradient.linear(green.darken(50%), blue), font: "DejaVu Sans Mono", weight: "black", size: 0.75em), radius: 0.125em, inset: 0.25em) *Listing*],
  supplement: [listing.],
  kind: "algorithm",
)

#let trick = custom-callout.with(
  color: yellow.darken(30%),
  header: [#emoji.wand *trick*],
  supplement: [trick],
  kind: "trick",
)

A number of predefined callouts are defined, the usage is the following:
#table(columns: (auto, auto, auto))[
  Inline callout
][
  ```typ
  #note[Short text]
  ```
][
  #note[Short text]
][
  Block, callout
][
  ```typ
  #note(title: [])[
    #lorem(10)
  ]
  ```
][
  #note(title: [])[
    #lorem(10)
  ]
][
  Block callout with title
][
  ```typ
  #note(title: [Title])[
    #lorem(10)
  ]
  ```
][
  #note(title: [Title])[
    #lorem(10)
  ]
][
  Reference a callout
][
  ```typ
  #note(
    title: [Title],
    label: <some-note>,
  )[
    #lorem(10)
  ]
  Ref: @some-note
  ```
][
  #note(title: [Title])[
    #lorem(10)
  ]
  Ref: @some-note
]

#let cells = {
  let cells = ();

  let functions = (
    ("note", note),
    ("idea", idea),
    ("example", example),
    ("question", question),
    ("exercise", exercise),
    ("info", info),
    ("todo", todo),
    ("todo-done", todo-done),
    ("proposition", proposition),
    ("observation", observation),
    ("theorem", theorem),
    ("lemma", lemma),
    ("corollary", corollary),
    ("proof", proof),
    ("definition", definition),
    ("postulate", postulate),
    ("warning", warning),
    ("remark", remark),
    ("important", important),
    ("danger", danger),
    ("quote", quote),
    ("algorithm", algorithm),
    ("listing", listing),
    ("trick", trick),
  )

  for (name, f) in functions {
    cells.push(raw("#"+name+"[Short text]", lang: "typ"));
    cells.push(f([Short text]));
    let label_name = "some-" + name;
    cells.push(raw("#"+name+"(\n  title: [Title],\n  label: <" + label_name + ">,\n)[\n  #lorem(10)\n]\nRef: @" + label_name, lang: "typ"));
    cells.push([
      #f(title: [Title], label: label(label_name))[#lorem(10)]
      Ref: #ref(label(label_name))
    ]);
  }

  cells
}

#table(
  columns: (auto, auto),
  ..cells
)

#listing(title: [Some algorithm])[
  ```rs
  type float = f32;
  fn ciao() -> real {
    42.0
  }
  ```
]