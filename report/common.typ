#import "@preview/lovelace:0.3.0": pseudocode-list
#import "custom-typst/boxes.typ": *

#let maybe-ref(target) = locate(loc => {
    let r = query(target, loc);
    let found = r.len() > 0;
    if found {
      //type(ref(target))
      ref(target)
    } else {
      target
    }
})

#let comment(body) = emph(text(green, "# " + body))

#let pseudo(..args) = {
  let content = box(
    fill: luma(240),
    inset: (left: 0.25em, right: 0.25em),
    radius: 0.25em,
    width: 100%,
    pseudocode-list(..args),
  );

  let keyword(it) = text(fill: red.darken(25%), it)

  let kws = (
    "fn",
    "if",
    "else",
    "while",
    "for",
    "loop",
    "return",
    "break",
    "continue",
    "let",
    "var",
  )
  for kw in kws {
    content = {
      show kw: keyword
      content
    }
  }

  show "assign": $<-$

  set text(font: "Liberation Mono", size: 0.75em)
  content
}

#let pseudo-fn(
  ref: none,
  it
) = {
  let color = blue.desaturate(30%).darken(30%)

  if ref == none {
    text(fill: color, it)
  } else {
    link(ref, text(fill: color, it))
  }
}

#let code-fn(
  ref: none,
  it
) = if ref == none {
  it
} else {
  link(ref, it)
}

// https://github.com/andreasKroepelin/lovelace/issues/20
#let pseudo-comment(body) = {
  h(1fr)
  text(size: .85em, fill: gray.darken(25%), sym.triangle.stroked.r + sym.space + body)
}

#let func(it) = text(font: "Liberation Mono", fill: blue.desaturate(30%).darken(30%), it)

#let DNI = locate(loc => {
    let target = <DNI-integration>;
    if query(target, loc).len() > 0 {
      link(target)[_DNI_]
    } else {
      target
    }
});

#let MCMC = locate(loc => {
    let target = <MCMC>;
    if query(target, loc).len() > 0 {
      link(target)[MCMC]
    } else {
      target
    }
});


#let l-rect = (it, stroke: black, radius: 0.25em, inset: 5pt) => rect(it, stroke: (
  left: stroke,
  right: none,
  top: stroke,
  bottom: stroke,
), radius: radius, inset: inset)

#let r-rect = (it, stroke: black, radius: 0.25em, inset: 5pt) => rect(it, stroke: (
  left: none,
  right: stroke,
  top: stroke,
  bottom: stroke,
), radius: radius, inset: inset)

#let full-rect = (it, stroke: black, radius: 0.25em, inset: 5pt) => rect(it, stroke: (
  left: stroke,
  right: stroke,
  top: stroke,
  bottom: stroke,
), radius: radius, inset: inset)

#let lrect(it) = l-rect(it, inset: 0.75em)
#let rrect(it) = r-rect(it, inset: 0.75em)
#let orect(it) = full-rect(it, inset: 0.75em)

#let grayed(content) = text(gray, content)

#let href(..args) = text(link(..args), rgb("#0000CD").darken(50%))

#import "@preview/pinit:0.2.0": pin, pinit-rect

#let lesson(date) = align(right, text(fill: gray, [#date #emoji.calendar]))

#let TODO = todo