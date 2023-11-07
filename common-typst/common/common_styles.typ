

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

  show link: link => text(link, rgb("#0000CD").darken(50%))
  show ref: ref => text(ref, rgb("#0000CD").darken(50%))

  //show image: image => []
  //show image: image => hide(image)
  //show: rest => hide(rest)

  import "@preview/bob-draw:0.1.0": *
  show raw.where(lang: "bob"): it => render(it.text)
  show raw.where(lang: "bob-5"): it => render(it.text, width: 5%)
  show raw.where(lang: "bob-10"): it => render(it.text, width: 10%)
  show raw.where(lang: "bob-15"): it => render(it.text, width: 15%)
  show raw.where(lang: "bob-20"): it => render(it.text, width: 20%)
  show raw.where(lang: "bob-25"): it => render(it.text, width: 25%)
  show raw.where(lang: "bob-30"): it => render(it.text, width: 30%)
  show raw.where(lang: "bob-35"): it => render(it.text, width: 35%)
  show raw.where(lang: "bob-40"): it => render(it.text, width: 40%)
  show raw.where(lang: "bob-45"): it => render(it.text, width: 45%)
  show raw.where(lang: "bob-50"): it => render(it.text, width: 50%)
  show raw.where(lang: "bob-55"): it => render(it.text, width: 55%)
  show raw.where(lang: "bob-60"): it => render(it.text, width: 60%)
  show raw.where(lang: "bob-65"): it => render(it.text, width: 65%)
  show raw.where(lang: "bob-70"): it => render(it.text, width: 70%)
  show raw.where(lang: "bob-75"): it => render(it.text, width: 75%)
  show raw.where(lang: "bob-80"): it => render(it.text, width: 80%)
  show raw.where(lang: "bob-85"): it => render(it.text, width: 85%)
  show raw.where(lang: "bob-90"): it => render(it.text, width: 90%)
  show raw.where(lang: "bob-95"): it => render(it.text, width: 95%)

  //let p = 5;
  //while p < 100 {
  //  let perc = str(p);
  //  show raw.where(lang: "bob-" + perc): it => render(it.text, width: percentage(p))
  //  p = p + 5;
  //  //[#("bob-" + perc)\
  //  //]
  //}

  body
}