

#let common_styles(
  body
) = {

  show raw.where(block: false): box.with(
    fill: luma(240),
    inset: (x: 3pt, y: 0pt),
    outset: (y: 3pt),
    radius: 2pt,
  )
  show raw.where(block: true): it => block(
    fill: luma(240),
    inset: 5pt,
    radius: 4pt,
  )[
    //#set align(left)
    //#set text(size: 8pt)
    #it
  ]

  set heading(numbering: "1.")
  set math.equation(numbering: "(1)")

  body
}