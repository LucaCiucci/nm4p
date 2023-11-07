#import "../../common-typst/defs.typ": *

#let xtasks = yaml("/mod_1/xtask.yaml")

#appendix(label: "extending-results-with-reweighting")[
    Extending results with reweighting
][
    Suppose we have the following distribution:
    $
    P_alpha (x) = G(x; mu = alpha, sigma^2)
    $
    where $alpha$ is the parameter.
    Suppose we made a Monte Carlo estimate of the expectation of some function $f$:
    $
    angle.l f angle.r _ P_alpha = integral d x space P_alpha (x) f(x)
    $
    we might expect that, by varying $alpha$, we could somewhat predict the expectation of $f$ without having to re-run the Monte Carlo simulation.

    In fact, we could use the *Importance sampling* aka *Reweighting*, that consists in using the following trivial identity:
    $
    angle.l f angle.r _ P &= integral d x space P(x) f(x) \
    &= integral d x space Q(x) space P(x) / Q(x) f(x) \
    &= lr(angle.l P/Q f angle.r)_Q
    $

    In a MC approach, given $X = "iid" tilde P_alpha$, we could then estimate the expectation value over $P_beta$:
    $
    overline(f) = sum_(x in X) f(x) P_beta/P_alpha
    $
    Which is pretty straightforward.

    == Error analysis

    This method has some problems in practice:
    + Variance divergence
    + Finite sample size

    === Variance divergence

    Using the CLT#footnote[Central Limit theorem]:
    $
    lr(angle.l P/Q f angle.r)_(Q, N)
    &= 1/N sum_i^N P(x_i)/Q(x_i) f(x_i) \
    &approx lr(angle.l P/Q f angle.r)_Q plus.minus sigma_((P/Q f))
    $
    So, while the _N-scaling_ is good ($tilde 1 / sqrt(N)$), the term $sigma_((P/Q f))$ can become quite large because of the pre-factor $P / Q$.

    For example, consider @importance_sampling_1:
    $
    sigma _((P f) / Q) ^ 2 = lr(angle.l ( P / Q f ) ^ 2 angle.r) _ Q - lr(angle.l P / Q f angle.r) _ Q ^ 2
    $
    And, while the second term is "ok", the first term can be very large.
    #figure(
        image("/mod_1/img/importance_sampling_1.jpg", width: 50%),
        caption: [
            Possible example of a large $sigma_((P/Q f))$.
        ]
    ) <importance_sampling_1>

    Consider this other example in @importance_sampling_2 where the two curves are pseudo-gaussian:
    $
    ((P f) / Q)^2 tilde delta^2
    $
    #figure(
        image("/mod_1/img/importance_sampling_2.jpg", width: 50%),
        caption: [
            #todo[]
        ]
    ) <importance_sampling_2>

    and the error will diverge in $delta$.

    This tells us that this method only works if *the two distributions are similar*.

    === Finite sample size

    One's hope is that, when the reweighting method fails, the variance will diverge indicating that the result we are getting is not precise enough.\
    Sadly, this is not true.

    We can imagine a counter-example as shown in @finite-variance-reweighting-counterexample. If the number of draws is finite, using the Čebyšëv inequality @chebyshev-wikipedia one can define an area where it is more likely for all the draws to be, i.e. with a certain probability $r$. This means that we have a probability $> r$ that no sample is _near_ the peak of $Q/P$.

    As an example, consider, like in @finite-variance-reweighting-counterexample:
    - $f tilde #[monotone]$
    - $P tilde /*Q tilde Q/P tilde */#[single-modal and finite variance]$
    - let $I(r)$ be the interval given by the Čebyšëv inequality
    - suppose $Q < P forall x in I(r)$ for the given $r$
    This means that, with probability $> r$, we have that every draw (${x_i} = X$) is in the interval $I$. But this implies that every outcome is in $Y subset f(I)$. But this implies that every weighted outcome ({$z_i = y_i Q(x_i)\/P(x_i)} = Z$) is in $Z subset [0, f(I_"max")]$ thus $"var"(Z) < I_"max"^2$. But this mena that, for every $Q| Q > P space forall x in I(r)$, $sigma_overline(z) < I_"max" \/ sqrt(N)$ *with probability $>r$*.

    #let c = {
        import "@preview/cetz:0.1.2": canvas, draw, plot
        canvas(length: 1cm, {
            import draw: *
            line((-0.5, 0), (7, 0), mark: (end: ">"))
            line((0, -0.5), (0, 4), mark: (end: ">"))
            let pts = ()
            let x = 0
            while x < 7 {
                pts.push((x, 3*calc.exp(-calc.pow(x - 2, 2)*5)))
                x += 0.025
            }
            for (pt1, pt2) in pts.zip(pts.slice(1)) {
                line(pt1, pt2, stroke: red)
            }
            let pts = ()
            let x = 0
            while x < 7 {
                pts.push((x, 3*calc.exp(-calc.pow(x - 4.5, 2)*5)))
                x += 0.025
            }
            for (pt1, pt2) in pts.zip(pts.slice(1)) {
                line(pt1, pt2)
            }
            let pts = ()
            let x = 0
            while x < 7 {
                pts.push((x, 3*calc.exp(-calc.pow(x - 4.5, 2)*5) * 3*calc.exp(-calc.pow(x - 2, 2)*5) * 2e6))
                x += 0.025
            }
            for (pt1, pt2) in pts.zip(pts.slice(1)) {
                line(pt1, pt2, stroke: gray)
            }
            rect((1, -0.5), (3.0, 3.5), fill: rgb("ff000030"), stroke: none)
            let r = 0.1;
            circle((2.0, 0.0), radius: r, fill: red, stroke: none)
            circle((1.9, 0.0), radius: r, fill: red, stroke: none)
            circle((1.7, 0.0), radius: r, fill: red, stroke: none)
            circle((1.5, 0.0), radius: r, fill: red, stroke: none)
            circle((2.25, 0.0), radius: r, fill: red, stroke: none)
            circle((2.5, 0.0), radius: r, fill: red, stroke: none)
            line(
                (0, 0),
                (6.5, 3),
                stroke: blue
            )
            content((1.5, 3.0), $P$)
            content((3.5, 3.0), $Q$)
            content((5.0, 3.0), $Q/P$)
            content((6.5, 2.75), $f$)
        })
    }
    #figure(
        c,
        caption: [
            The $f$ function in blue is a step function with values $a$ or $b$.
            The red and black curves are $P$ and $Q/P$ respectively. The red area is the likely interval derived using the Čebyšëv inequality.
            The red dots are some possible draws.
        ]
    ) <finite-variance-reweighting-counterexample>

    We conclude that, for a finite number of samples, by varying the distribution too much, the reweighting method gives out a variance which is not representative of the actual confidence bound.

    To test this hypothesis, we can run a simulation where we sample a distribution using $P = G(0, 1)$ and then reweight it using $Q = G(mu, 1)$. We compute the estimator $overline(x)$ by reweighting.\
    Results are shown in @reweighting-failure where we can observe that, for small $mu$, the reweighting method gives a good estimate of the expected values, but, as $mu$ increases, the reweighted value converges to $0$ and the same happens for the variance. This strongly limits the possible applications of the reweighting method since we cannot be sure that the variance is a good estimate of the confidence bound.

    #figure(
        image("/mod_1/img/plots/reweighting-failure.svg", width: 50%),
        caption: [
            example #footnote(raw(xtasks.reweighting-failure, block: false, lang: "sh")) of reweighting failure.
        ]
    ) <reweighting-failure>

    However, we can still use the reweighting method to get a good estimate of the expected value in a very small range, thous we could use automatic differentiation (@auto-diff) to compute derivatives of the expected value with respect to the parameters of the distribution.
]