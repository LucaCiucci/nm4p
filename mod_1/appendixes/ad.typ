#import "../../common-typst/defs.typ": *

#appendix(label: "auto-diff")[
    Automatic Differentiation (AD)
][
    AD provides a way to compute the derivative of a function by using the chain rule without explicitly computing finite differences which would require us to choose a finite difference step size.

    AD is implemented using the #link("https://github.com/LucaCiucci/differential-rs")[`differential`] #footnote[https://github.com/LucaCiucci/differential-rs] package I'm currently developing where `Differential` is just a product type of the function and its derivative. By defining all the basic operations, we can compute the derivative of a large set of functions.

    Suppose, for example, that we want to compute the derivative in $x = 3$ of the function $f(x) = x^2 + sin(x)$. We could define:
    ```rs
    fn f(x: Differential) -> Differential {
        x * x + x.sin()
    }
    ```
    and then do the following:
    + we want the derivative with respect to $x$, the derivative of $x$ with respect to itself is $1$;
    + hence define ```rs x = Differential::new(3.0, 1.0)```
    + compute `f(x)` and extract the derivative.
    This translates into: ```rs f((3.0, 1.0).into()).derivative```
]