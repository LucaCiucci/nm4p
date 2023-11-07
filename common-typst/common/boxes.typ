
#import "common_styles.typ": *

#show: common_styles

#outline()

== `callout`

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

`callout` creates a box with a header and a body. It is used inside the other macros.

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

== Note

#let note(
  title: [],
  body
) = callout(
  color: rgb("#2ecc40"),
  header: [#emoji.pencil *Note*: #title],
  //header: [✎ *Note*: #title],
  body
)

#table(
  columns: (auto, auto),
  [
    ```typ
    #note[
      #lorem(10)
    ]
    ```
  ],
  [
    #note[
      #lorem(10)
    ]
  ],
  [
    ```typ
    #note(
      title: [Hello There]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #note(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ],
)

== Example

#let example(
  title: [],
  body
) = callout(
  color: gray,
  //header: [#emoji.circle *example*: #title],
  header: [🕮 *example*: #title],
  body
)

#table(
  columns: (auto, auto),
  [
    ```typ
    #example(
      title: [Hello There]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #example(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ]
)

== Question

#let question(
  title: [],
  body
) = callout(
  color: rgb("#0074d9"),
  //header: [#emoji.circle *question*: #title],
  header: [🕮 *question*: #title],
  body
)

== Exercise

#let exercise(
  title: [],
  body
) = callout(
  color: rgb("#0074d9"),
  //header: [#emoji.circle *exercise*: #title],
  header: [🕮 *exercise*: #title],
  body
)

#table(
  columns: (auto, auto),
  [
    ```typ
    #exercise(
      title: [Hello There]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #exercise(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ]
)

== Info

#let info(
  title: [],
  body
) = callout(
  color: rgb("#2ecc40"),
  //header: [#emoji.info *Info*: #title],
  header: [🛈 *Info*: #title],
  body
)

#table(
  columns: (auto, auto),
  [
    ```typ
    #info(
      title: [Hello There]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #info(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ],
)

== Todo

// A TODO
#let todo(
  title: [],
  done: false,
  body
) = {
  //callout(color: rgb("#8949e2"), header: [TODO], body)
  //callout(color: rgb("#8949e2a0"), header: [TODO], body)
  let em = if done {
    //emoji.checkmark
    emoji.ballot.check
  } else {
    emoji.square
  }
  //callout(color: rgb("#3498db"), header: [#em TODO], if done {strike(body) } else { body })
  callout(color: rgb("#BA55D3"), header: [#em *TODO*: #title], if done {strike(body) } else { body })
}

#table(
  columns: (auto, auto),
  [
    ```typ
    #todo[
      #lorem(10)
    ]
    ```
  ],
  [
    #todo(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ],
  [
    ```typ
    #todo(
      title: [Hello There],
      done: true
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #todo(
      title: [Hello There],
      done: true
    )[
      #lorem(10)
    ]
  ],
)

== Proposition

#let theorem_like(
  header,
  prop,
  proof,
) = {
  if proof != [] {
      prop = [
          #prop\
          *Proof*\
          #proof
          #sym.square
      ]
  }
    callout(
      color: gray,
      header: header,
      prop
  )
}

#let proposition(
  title: [],
  prop,
  proof: [],
) = theorem_like(
  [
    #sym.circle #underline[*proposition*]: #title
  ],
  prop,
  proof,
)

#table(
  columns: (auto, auto),
  [
    ```typ
    #proposition(
      title: [Hello There]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #proposition(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ],
  [
    ```typ
    #proposition(
      title: [Hello There],
      [
        #lorem(5)
      ],
      proof: [
        #lorem(10)
      ]
    )
    ```
  ],
  [
    #proposition(
      title: [Hello There],
      [
        #lorem(5)
      ],
      proof: [
        #lorem(10)
      ]
    )
  ],
)

== Observation

#let observ(
  title: [],
  prop,
  proof: [],
) = theorem_like(
  [
    #sym.circle #underline[*observation*]: #title
  ],
  prop,
  proof,
)

#table(
  columns: (auto, auto),
  [
    ```typ
    #observ(
      title: [Hello There]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #observ(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ],
  [
    ```typ
    #observ(
      title: [Hello There],
      [
        #lorem(5)
      ],
      proof: [
        #lorem(10)
      ]
    )
    ```
  ],
  [
    #observ(
      title: [Hello There],
      [
        #lorem(5)
      ],
      proof: [
        #lorem(10)
      ]
    )
  ],
)

== Theorem

#let theorem(
  title: [],
  prop,
  proof: [],
) = theorem_like(
  [
    #sym.square #underline[*theorem*]: #title
  ],
  prop,
  proof,
)

#table(
  columns: (auto, auto),
  [
    ```typ
    #theorem(
      title: [Hello There]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #theorem(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ],
  [
    ```typ
    #theorem(
      title: [Hello There],
      [
        #lorem(5)
      ],
      proof: [
        #lorem(10)
      ]
    )
    ```
  ],
  [
    #theorem(
      title: [Hello There],
      [
        #lorem(5)
      ],
      proof: [
        #lorem(10)
      ]
    )
  ],
)

== Lemma

#let lemma(
  title: [],
  prop,
  proof: [],
) = theorem_like(
  [
    #sym.square #underline[*lemma*]: #title
  ],
  prop,
  proof,
)

#table(
  columns: (auto, auto),
  [
    ```typ
    #lemma(
      title: [Hello There]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #lemma(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ],
  [
    ```typ
    #lemma(
      title: [Hello There],
      [
        #lorem(5)
      ],
      proof: [
        #lorem(10)
      ]
    )
    ```
  ],
  [
    #lemma(
      title: [Hello There],
      [
        #lorem(5)
      ],
      proof: [
        #lorem(10)
      ]
    )
  ],
)

== Corollary

#let corollary(
  title: [],
  prop,
  proof: [],
) = theorem_like(
  [
    #sym.square #underline[*corollary*]: #title
  ],
  prop,
  proof,
)

#table(
  columns: (auto, auto),
  [
    ```typ
    #corollary(
      title: [Hello There]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #corollary(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ],
  [
    ```typ
    #corollary(
      title: [Hello There],
      [
        #lorem(5)
      ],
      proof: [
        #lorem(10)
      ]
    )
    ```
  ],
  [
    #corollary(
      title: [Hello There],
      [
        #lorem(5)
      ],
      proof: [
        #lorem(10)
      ]
    )
  ],
)

== Proof

#let proof(
  title: [],
  proof,
) = {
  callout(
      color: gray,
      header: [#sym.square #underline[*proof*]: #title],
      proof// + sym.square
  )
}

#table(
  columns: (auto, auto),
  [
    ```typ
    #proof(
      title: [Hello There]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #proof(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ],
)

== Definition

#let definition(
  title: [],
  proof,
) = callout(
  color: gray,
  header: [#sym.circle.filled #underline[*definition*]: #title],
  proof
)

#table(
  columns: (auto, auto),
  [
    ```typ
    #definition(
      title: [Hello There]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #definition(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ],
)

== Warning

#let warning(
  title: [],
  body
) = {
  //callout(color: rgb("#b47e09"), header: [Warning], body)
  callout(color: rgb("#f1c40f"), header: [#emoji.warning *Warning*: #title], body)
  //callout(color: orange, header: [Warning], body)
}

#table(
  columns: (auto, auto),
  [
    ```typ
    #warning[
      #lorem(10)
    ]
    ```
  ],
  [
    #warning[
      #lorem(10)
    ]
  ],
  [
    ```typ
    #warning(
      title: [Hello There]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #warning(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ],
)

== Remark

#let remark(
  title: [],
  body
) = {
  callout(color: rgb("#e74c3c"), header: [#emoji.excl.double *Remark*: #title], body)
  //callout(color: gray, header: [Remark], body)
  //callout(color: blue, header: [Remark], body)
  //callout(color: aqua, header: [Remark], body)
  //callout(color: teal, header: [Remark], body)
  //callout(color: eastern, header: [Remark], body)
}

#table(
  columns: (auto, auto),
  [
    ```typ
    #remark[
      #lorem(10)
    ]
    ```
  ],
  [
    #remark[
      #lorem(10)
    ]
  ],
  [
    ```typ
    #remark(
      title: [Hello There]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #remark(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ],
)

== Important

#let important(
  title: [],
  body
) = callout(
  color: rgb("#e74c3c"),
  header: [#emoji.excl.double *Important*: #title],
  body
)

#table(
  columns: (auto, auto),
  [
    ```typ
    #important[
      #lorem(10)
    ]
    ```
  ],
  [
    #important[
      #lorem(10)
    ]
  ],
  [
    ```typ
    #important(
      title: [Hello There]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #important(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ],
)

== Danger

#let danger(
  title: [],
  body
) = callout(
  color: rgb("#e74c3c"),
  header: [#emoji.excl.double *Danger*: #title],
  body
)

#table(
  columns: (auto, auto),
  [
    ```typ
    #danger[
      #lorem(10)
    ]
    ```
  ],
  [
    #danger[
      #lorem(10)
    ]
  ],
  [
    ```typ
    #danger(
      title: [Hello There]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #danger(
      title: [Hello There]
    )[
      #lorem(10)
    ]
  ],
)

#let quote(
  title: [],
  source: [],
  body
) = {
  callout(
    //color: rgb(34, 34, 34),
    color: rgb("#2c3e50"),
    header: [❞ *Quote*: #title],
    [
      #body
      #align(right, source)
    ]
  )
}

#table(
  columns: (auto, auto),
  [
    ```typ
    #quote[
      #lorem(10)
    ]
    ```
  ],
  [
    #quote[
      #lorem(10)
    ]
  ],
  [
    ```typ
    #quote(
      title: [Hello There],
      source: [Obi Wan Kenobi]
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #quote(
      title: [Hello There],
      source: [Obi Wan Kenobi]
    )[
      Hello There
    ]
  ],
)

== Algorithm

#let typ_label = label

#let algorithm(
  title: [],
  label: "",
  body
) = {
  show figure.where(kind: "algorithm"): f => f.counter.display()

  let header = [#emoji.gear *Algorithm*];
  if label != "" {
    header = header + [ #figure([], kind: "algorithm", supplement: "Algorithm", caption: []) #typ_label(label)];
  }
  header = header + [: #title];

  callout(
    color: rgb("#2c3e50"),
    header: header,
    body
  )
}

#table(
  columns: (auto, auto),
  [
    ```typ
    #algorithm[
      #lorem(10)
    ]
    ```
  ],
  [
    #algorithm[
      #lorem(10)
    ]
  ],
  [
    ```typ
    #algorithm(
      title: [Hello There],
      label: "hello"
    )[
      #lorem(10)
    ]
    ```
  ],
  [
    #algorithm(
      title: [Hello There],
      label: "hello"
    )[
      #lorem(10)
    ]
  ],
)

#quote(
  source: [Obi Wan Kenobi]
)[
  listen... _we fucked up_
]