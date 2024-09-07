#import "../../common-typst/defs.typ": *

#appendix(label: "ADMC")[
    Automatic Differentiation in Monte Carlo simulations (ADMC)
][
    We can combine Automatic Differentiation (@auto-diff) with the Reweighting Method (@extending-results-with-reweighting):

    By defining the differential quantity $alpha eq.def (alpha^((0)), alpha^((1)))$, we can apply reweighting:
    $
    lr(angle.l O angle.r) eq.def lr(angle.l (O^((0)), O^((1))) angle.r) &= sum_(i=1)^N underbrace(O_(alpha, x_i), (a)) underbrace((P_((alpha^((0)), alpha^((1))))(x_i)) / (P_((alpha^((0)), 0))(x_i)), (b))\
    $ <admc-rew>
    where ${x_i} tilde P_((alpha^((0)), 0))$.

    In literature (@stochastic-ADMC), the dependencies of $(a)$ and $(b)$ on $alpha$ are usually referred to as *connected* and *disconnected* *contributions*, respectively.\
    In our case of interest, we will have no connected contributions, but this is just a trivial case of the general formula.

    // TODO leggi https://arxiv.org/abs/1911.09117

    == Curve fitting magic

    What is the purpose of this stuff? Suppose we made a single MC simulation for a fixed $alpha$. This might not give us all the information we need. For example, we might be interested to perform a curve fit with a known law, but if the model has more than one parameter, we clearly cannot fit it.

    A walkaround that might be useful is to extract, from the same simulations, not only the value of the observable, but also its derivative with respect to the parameter $alpha$, and this problem can be easily addressed with ADMC. This is actually nothing new, it is just the simultaneous evaluation of two (somewhat related) different quantities.

    As trivial example, consider the test parameter-dependent distribution similar to the one used in @auto-diff: $P_alpha = G(mu = a + alpha, sigma^2 = 1)$.

    If we perform a single simulation and just evaluate the observable $O = x$, we get a single point (@admc-trivial-fit (a)). We can use AD to compute its derivative (@admc-trivial-fit (b)) and then fit the curve (@admc-trivial-fit (c)).

    #let c = {
        import "@preview/cetz:0.1.2": canvas, draw, plot
        let dy = 0.1;
        let base = {
            import draw: *
            line((-0.5, 0), (4, 0), mark: (end: ">"))
            line((0, -0.5), (0, 3), mark: (end: ">"))
            line((0, 0.5), (4, 3), stroke: gray)
            let sigma-y = 0.3;
            let w-x = 0.1;
            line((1.5, 1.5 + dy - sigma-y), (1.5, 1.5 + dy + sigma-y), stroke: blue)
            line((1.5 - w-x, 1.5 + dy - sigma-y), (1.5 + w-x, 1.5 + dy - sigma-y), stroke: blue)
            line((1.5 - w-x, 1.5 + dy + sigma-y), (1.5 + w-x, 1.5 + dy + sigma-y), stroke: blue)
            circle((1.5, 1.5 + dy), radius: 0.1, fill: blue, stroke: none)
        };
        let deriv = {
            import draw: *
            let d = 2.5/4;
            let dd = 0.25;
            let a = 0.5;
            line(
                (1.5 - a, 1.5 + dy - a * (d + dd)),
                (1.5 + a, 1.5 + dy + a * (d + dd)),
                (1.5 + a, 1.5 + dy + a * (d - dd)),
                (1.5 - a, 1.5 + dy - a * (d - dd)),
                stroke: none,
                fill: red
            )
        }
        let pts = {
            let pts = ()
            let a = 0.1
            let f = x => calc.sqrt(calc.pow(x - 1.5, 2) / 10 + a*a) - a
            let x = 0;
            while x <= 4.001 {
                let y = (x - 1.5) * 2.5/4 + f(x) + 1.9;
                pts.push((x, y));
                x += 0.1;
            }
            let x = 4;
            while x >= -0.0001 {
                let y = (x - 1.5) * 2.5/4 - f(x) + 1.25;
                pts.push((x, y));
                x -= 0.1;
            }
            pts
        };
        (
            canvas(length: 1cm, {
                import draw: *
                base
                line(..pts, stroke: none, fill: none)
            }),
            canvas(length: 1cm, {
                import draw: *
                base
                deriv
                line(..pts, stroke: none, fill: none)
            }),
            canvas(length: 1cm, {
                import draw: *
                base
                deriv
                line(..pts, stroke: none, fill: rgb("#00008888"))
                //content((0, 0), [#pts])
            })
        )
    }
    #figure(
        stack(
            stack(
                stack(c.at(0), [(a)]),
                stack(c.at(1), [(b)]),
                stack(c.at(2), [(c)]),
                dir: ltr,
                spacing: 0.5cm,
            ),
        ),
        caption: [
            Single point from a single simulation (a), its derivative (b), and the fitting line (c).
        ]
    ) <admc-trivial-fit>

    This was just a trivial example, if the function is more complex, we could potentially compute higher order derivatives in order to fit all the parameters.\
    If, for example, we have a model with $M$ parameters, we might compute $M - 1$ derivatives and solve for the parameters. This is not always analytically possible or computationally simple, but theoretically possible.\
    Does this means that, form a single simulation, we can extract the behavior on the whole parameter space? The answer is certainly yes, but obviously the error might be huge when we are far from the point where we performed the simulation on even though it should converge as we add points as $O(1 \/ sqrt(N))$.

    What if we have multiple point with derivatives? Does this method allow us to increase the precision of the fit? The answer is *no*!, and this because derivatives do not carry any additional information about the model parameters.

    To further understand this, we shall take a step back.
    To make a punctual estimation of the observable, we *usually* use the arithmetic average estimator (as we've done in ???? metti nell'introduzione):
    $
    y = 1/N sum f(x_i)
    $
    where now $f(x_i) eq.def O_(x_i)$.
    Like we've done in @admc-rew, we can use reweighting to extend the results:
    $
    y(lambda) &= 1/N sum f_lambda (x_i) (P_lambda (x_i)) / (P_(lambda_0)(x_i))\
    &eq.def 1/N sum f_lambda (x_i) w_lambda (x_i)\ // TODO say that w is the reweighting factor
    &eq.def 1/N sum g_lambda (x_i)\
    $
    We can then define the $n$-th derivative of $y$ as:
    $
    y^((n)) &= 1/N sum diff_lambda^((n)) g_lambda (x_i)\
    &eq.def 1/N sum h_lambda^((n)) (x_i)\
    $

    Now, the non-trivial point is that there is a map $y^((n)) <--> y^((m))$, and this implies that the Fisher Information over any parameter is _the same_. This point needs some clarifications.\ // TODO reference!!!!
    First of all, we consider the case in which variances are small enough so that the map is invertible.\
    Secondly, we have to clarify what _the same_ means.\

    Here, we denote the fisher information of a statistics $x$ over the parameter $mu$ as $I_mu^x$.\
    With this notation, we say that the Fisher information of two statistics $x$ and $s_x$ are _the same_ if:
    $
    I^x_mu underbracket(=, (1)) I^s_x_mu underbracket(=, (2)) I^((x, s_x))_mu
    $
    where $(x, s_x)$ denotes the joint statistics#footnote[https://en.wikipedia.org/wiki/Joint_probability_distribution]. This means:
    + the two statistics carry the same amount of information
    + we cannot extract more information from the joint statistics than from the two statistics separately
    #warning[
        (2) means that while we can extrapolate an infinite number of derivatives from a single simulation, we cannot extract more information on the model parameters by simultaneously fitting any number of derivatives.
        #todo[
            clarify this point and show how this translates into a constraint
        ]// TODO
    ]

    In our case $x <--> s_x$, where $x <- y^((n))$ and $s_x <- y^((m))$, so the information they carry is effectively _the same_.
    #proof[
        If there is a bijection $x <--> s_x$, then, for consistency:
        $
        cal(L)_mu(s_x) d s_x = cal(L)_mu(x) d x
        $ <x-sx-consistency>
        By definition:
        $
        I_mu^x = E[(diff_mu ln cal(L)_mu (x))^2]
        $
        $
        I_mu^(s_x) &= E[(diff_mu ln cal(L)_mu (s_x))^2]\
        &= E[(1/(cal(L)_mu (s_x)) diff_mu cal(L)_mu (s_x))^2]
        $
        by using the definition of expectation value:
        $
        I_mu^(s_x)
        &= integral (1/(cal(L)_mu (s_x)) diff_mu cal(L)_mu (s_x))^2 cal(L)_mu (s_x) d s_x\
        #[@x-sx-consistency] --> space &= integral (1/(cal(L)_mu (x) (d x)/(d s_x)) space (d x)/(d s_x)diff_mu cal(L)_mu (x))^2 cal(L)_mu (x) d x\
        &= integral (1/(cal(L)_mu (x)) space diff_mu cal(L)_mu (x))^2 cal(L)_mu (x) d x\
        #[by definition] --> space &= I_mu^x
        $
        This proves (1).
        In the same way, we can prove (2):
        $
        I_mu^((x, s_x)) &= integral integral (1/(cal(L)_mu (x, s_x)) diff_mu cal(L)_mu (x, s_x))^2 cal(L)_mu (x, s_x) d x d s_x\
        #[(a)] --> space &= integral integral (1/(cal(L)_mu (x) delta(x - s_x)) diff_mu cal(L)_mu (x) delta(x - s_x))^2 cal(L)_mu (x) delta(x - s_x) d x d s_x\
        #[(b)] --> space &= integral (1/(cal(L)_mu (x)) diff_mu cal(L)_mu (x))^2 cal(L)_mu (x) d x\
        &= I_mu^x
        $
        where:
        - (a) is because $x <--> s_x$
        - (b) is provable by taking the $delta$ as the limit of some function sequence.
    ]

    This result means that from a single MC simulation, we cannot extract more information on the model parameters by simultaneously fitting any number of derivatives, but we can extract some different information, for example the taylor expansion of the model around the point where we performed the simulation. This might be particularly useful in the case the model is analytical, an example usages will be shown later.

    What if we try to use derivatives to perform a fit with a model?
    To answer this question, suppose we want to perform a least-squares fit. We would want to minimize the following quantity @levenberg-marquardt:
    $
    chi^2 = (bold(y) - hat(bold(y)))^T cal(W) (bold(y) - hat(bold(y)))
    $
    where $y_i$ is the value of the observable and $hat(y_i)$ is the value of the model.
    According to @levenberg-marquardt, the $cal(W)$ is formally the inverse of the covariance matrix of the data.
    #todo[
        I could not find a reference for this, but it is a reasonable assumption.\
        In fact, least-squares fit is formally meaningful only in the case that the data is normally distributed and, in this context, the data ${x_i}$ is distributed as:
        $
        tilde exp(-1/2(bold(x) - hat(bold(x)))^T cal(W) (bold(x) - hat(bold(x))))
        $
        By changing variables into $y$ where the correlations are null, we get:
        $
        ... &= exp(-1/2delta bold(y)^T cal(W)prime delta bold(y))\
        &= exp(-1/2delta bold(y)^T "diag"{1 \/ sigma_y_i} delta bold(y))\
        &= exp(-1/2delta bold(y)^T C'^(-1) delta bold(y))\
        $
        where $C prime$ is the covariance matrix of the data in the new base, this means that $cal(W) prime = C'^(-1) <==> cal(W) = C^(-1)$.
    ]
    In our case, the covariance matrix
    $
    Sigma = mat(
        sigma_(y^((n))y^((n))), sigma_(y^((n))y^((m)));
        sigma_(y^((m))y^((n))), sigma_(y^((m))y^((m)));
    )
    $
    has unit correlations since there is the bijection $y^((n)) <--> y^((m))$, so:
    $
    Sigma &= mat(
        sigma_(y^((n)))^2, sigma_(y^((n)))sigma_(y^((m)));
        sigma_(y^((m)))sigma_(y^((n))), sigma_(y^((m)))^2;
    )\
    &= mat(
        sigma_(y^((n))), 0;
        0, sigma_(y^((m)));
    ) mat(
        1, 1;
        1, 1;
    ) mat(
        sigma_(y^((n))), 0;
        0, sigma_(y^((m)));
    )
    $
    But this is not invertible!\
    If we re-define:
    $
    Sigma &= mat(
        sigma_(y^((n))), 0;
        0, sigma_(y^((m)));
    ) mat(
        1, c;
        c, 1;
    ) mat(
        sigma_(y^((n))), 0;
        0, sigma_(y^((m)));
    )
    $ <admc-sigma-factorized>
    we could formally take the inverse in the limit $c -> 1$.\
    This allows us to compute the covariance matrix of the model parameters:
    $
    V_bold(p) = (bold(J)^T cal(W) bold(J))^(-1)
    $
    where $J$ is the jacobian matrix of the model parameters.
    #todo[
        find a formal justification of this. If I can recall correctly, it has something to to with F-test and the fact that $bold(J)^T cal(W) bold(J)$ is the approximate hessian matrix of the model parameters and has something to do with the Fisher information matrix (I think it "is" the Fisher information matrix, but I'm not sure).
    ]
    $
    V_bold(p) &= (bold(J)^T cal(W) bold(J))^(-1)\
    &= (bold(J)^T Sigma^(-1) bold(J))^(-1)\
    $
    In the case we have just a single pair of derivatives and a model with Two parameters:
    $
    V_bold(p) &= bold(J)^(-1) Sigma (bold(J)^T)^(-1)
    $
    and this means that, in some basis, $V_bold(p)$ takes the form @admc-sigma-factorized
    #todo[
        generalize with more points ($J$ not square), maybe it is enough to say that $Sigma$ is singular $==>$ the hole matrix $(bold(J)^T Sigma^(-1) bold(J))^(-1)$ will be somehow singular, too.
    ]
    What this teaches us is that by throwing at a fit two completely correlated data we are effectively imposing a constraint on the model parameters which is not easily implementable in the fit, but certainly formally possible.

    This also teaches us that fitting derivatives does not give any additional Fisher information on the parameters (i.e. we would not reduce uncertainties) but just deducing constraints on the model parameters.

    #warning(title: [do not throw fully correlated data into fits!])[
        This would be meaningless in practice because:
        + it is difficult since the covariance matrix is not invertible, we would have to take limits
        + imposing these constraints would quickly lead to overdetermined systems

        More on (2).\
        If the system is overdetermined, we would have numerical problems even if the model is correct, but we could possibly find some dirty walkaround.\
        In the real case, the model might not be correct, but even if it was, we would have to consider that correlations within the fit are not always linear (as shown in @admc-correlated-data-non-linearity (b)) and this would lead to the fixing of an incorrect constraint that would effectively make the fit inconsistent.

        #let c = {
            import "@preview/cetz:0.1.2": canvas, draw, plot
            let xx = (
                    0,
                    0.5,
                    -0.75,
                    1.0,
                    0.1,
                    0.15,
                    0.2,
                    0.3,
                    -0.1,
                    -0.12154,
                    -0.1945,
                    -0.3,
                    -0.4,
                )
            (
                canvas(length: 1cm, {
                    import draw: *
                    line((-1.5, 0), (1.5, 0), mark: (end: ">"))
                    line((0, -1.5), (0, 1.5), mark: (end: ">"))
                    let f = (x) => x
                    for x in xx {
                        let y = f(x)
                        circle((x, y), radius: 0.1, stroke: blue)
                    }
                    let x = -1.5
                    let pts = ()
                    while x <= 1.5001 {
                        let y = f(x)
                        pts.push((x, y))
                        x += 0.1
                    }
                    line(..pts, stroke: red)
                }),
                canvas(length: 1cm, {
                    import draw: *
                    line((-1.5, 0), (1.5, 0), mark: (end: ">"))
                    line((0, -1.5), (0, 1.5), mark: (end: ">"))
                    let f = (x) => x + x*x / 2 - 0.2
                    for x in xx {
                        let y = f(x)
                        circle((x, y), radius: 0.1, stroke: blue)
                    }
                    let x = -1.5
                    let pts = ()
                    while x <= 1.001 {
                        let y = f(x)
                        pts.push((x, y))
                        x += 0.1
                    }
                    line(..pts, stroke: red)
                }),
            )
        }
        #figure(
            stack(
                stack(
                    stack(c.at(0), [(a)], spacing: 5pt),
                    stack(c.at(1), [(b)], spacing: 5pt),
                    dir: ltr,
                    spacing: 0.5cm,
                ),
            ),
            caption: [
                Perfectly correlated data in the linear case (a) and in a case with second order corrections (b).
            ]
        ) <admc-correlated-data-non-linearity>
    ]

    Now that we've understood the limits of this approach, let's present some very basic practical application.

    == Data interpolation

    Suppose we've made some MC simulations for a number of parameter values. We would get a set of points in the parameter space, and we would like to inspect the behavior of the model in the whole parameter space.\
    An obvious thing to do is to try to interpolate the data using the derivative and a piecewise-cubic like shown in @cubic-interpolation-example.
    This would allow us to visually inspect the behavior of the data *without having a model* or to approximately find a range for maximums, minima, inflection points, etc.\

    We could possibly go even further and, form a single point, extract the taylor expansion of the model around that point.\
    This is of very little use though because the taylor expansion could diverge quite quickly around the point. But we could do the same thing with two or more points and get a better approximation of the model in the case we know it is analytical.

    Suppose for example, that we are interested in finding the maximum of the unknown function around a point.\
    We could choose an order $K$, compute $K$ derivatives at each point, and find the $N(K+1)-1$ order polynomial that interpolates the data. This polynomial would have a taylor expansion that matches the expansion around each point.\
    This looks reasonable, but in reality interpolating trough points that are distant to the point of interest might not increase the precision of the value of the maximum, which is determined mostly by the nearest points and what the distant points are doing is just increasing the order of the polynomial, which might not always be a good thing since it might increase the oscillations of the polynomial and also lead to numerical problems.

    What looks reasonable though, is:
    + use a piecewise interpolation to find the point of interest
    + concentrate the numerical effort in on two points "near" the point of interest
    + extract the interpolating polynomial of the two points with order $2(K+1)-1$ where $K$ is the order of the taylor expansion around the points
    + evaluate the quantities of interest for different $K$ (always verifying that the point of interest is still inside the range), truncating when the higher order corrections are much smaller than the statistical uncertainties.

    === A toy problem

    Consider the model:
    $
    f(alpha) = 1 / (alpha^2 + a)
    $
    and the the following distribution:
    $
    P_alpha (x) = G(mu = f(alpha), sigma^2 = 1)
    $
    and just compute the expectation value of $x$.\
    After running the simulation, forgetting about the model, we want find the peak.

    
]