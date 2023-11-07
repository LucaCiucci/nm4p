#import "../../common-typst/defs.typ": *

#appendix(label: "andamento_1_delta")[Andamento $1\/delta$][

    #todo(title:"wrong and incomplete")[
    Possiamo infatti, dati $a$ e $b$ abbiamo, nel nostro caso, la @rho-mh-uniform da cui, dato $a$, il valore di aspettazione di $rho$.  ????
    Scriviamo la nostra $A$:
    $
    A(a, b) = 1 / delta Theta(delta / 2 - abs(b - a))
    $
    per cui, integrando su $a$ e su b:
    $
    E[rho(a, b)] = E_(a)[E_(b)[rho(a, b)]]
    &= integral_(-infinity)^(+infinity) p(a) d a integral_(-infinity)^(+infinity) rho(a, b) A(a -> b) d b \
    &= integral_(-infinity)^(+infinity) p(a) d a integral_(a - delta / 2)^(a + delta / 2) rho(a, b) 1 / delta d b \
    $
    #todo[
        non troppo formale il secondo = ?
    ]
    inserendo @rho-mh-uniform:
    $
    E[rho(a, b)]
    &= 1 / delta integral_(-infinity)^(+infinity) p(a) d a integral_(a - delta / 2)^(a + delta / 2) min(1, p(b) / p(a)) d b \
    $ <e_rho_tmp_1>

    $
    E[rho(a, b)]
    &= 1 / delta integral_(-infinity)^(+infinity) p(a) d a (integral_(a - delta / 2)^(a + delta / 2) f Theta(p(b) - p(a)) d b + integral_(a - delta / 2)^(a + delta / 2) f Theta(p(a) - p(b)) d b) \
    &= 1 / delta integral_(-infinity)^(+infinity) p(a) d a (integral_(a - delta / 2)^(a + delta / 2) Theta(p(b) - p(a)) d b + integral_(a - delta / 2)^(a + delta / 2) f Theta(p(a) - p(b)) d b) \
    $
    $
    f = min(1, p(b) / p(a))
    $
    Ma $forall p(a)$:
    $
    integral_(a - delta / 2)^(a + delta / 2) Theta(p(b) - p(a)) d b < infinity
    $
    #proof[
        TODO
    ]

    #proposition(
        [
            $
            integral_a^b min(f, g) <= min(integral_a^b f, integral_a^b g)
            $ <integral-min-tmp>
            with $f,g >= 0$, $integral_a^b f,g in RR$
        ],
        proof: todo[...]
    )

    Using @integral-min-tmp:
    $
    E[rho(a, b)]
    &<= 1 / delta integral_(-infinity)^(+infinity) p(a) d a min(delta, integral_(a - delta / 2)^(a + delta / 2) p(b) / p(a) d b) \
    $
    Ora, dato che $integral_(-x)^(+x)p(b) d b -> 1$ converge:
    $
    -> 1 / delta integral_(-infinity)^(+infinity) p(a) d a min(delta, integral_(a - delta / 2)^(a + delta / 2) p(b) / p(a) d b) \
    $

    $
    exists delta: min(delta, integral_(a - delta / 2)^(a + delta / 2) p(b) / p(a) d b) = integral_(a - delta / 2)^(a + delta / 2) p(b) / p(a) d b
    $
    So:
    $
    E[rho(a, b)]
    &<= 1 / delta integral_(-infinity)^(+infinity) p(a) / p(a) d a integral_(a - delta / 2)^(a + delta / 2) p(b) d b \
    $

    #todo[
        rilassa questa condizione qui sotto
    ]

    Ora, sappiamo che
    $
    forall a in RR: integral_(-infinity)^(+infinity) p(b) d b = lim_(c -> infinity) integral_(a-c)^(a+c) p(b) d b = 1
    $
    quindi
    $
    forall epsilon.alt in (0, 1) exists c > 0: 1 - integral_(a-c)^(a+c) p(b) d b < epsilon.alt
    $
    Siamo interessati a fare il limite per $delta -> infinity$, quindi poniamo ora $delta > c$ e riprendendo @e_rho_tmp_1:
    $
    E[rho(a, b)]
    &= 1 / delta integral_(-infinity)^(+infinity) p(a) d a (integral_(a - delta)^(a - c) f d b + integral_(a - c)^(a + c) f d b + integral_(a + c)^(a + delta) f d b) \
    $
    con $f = min(1, p(b) / p(a))$

    ---

    Ora, supponendo che $p(x) -> 0$ per $abs(x) -> infinity$, $forall a exists Delta: p(x) < p(a) forall x > Delta$, per cui:
    $
    E[rho(a, b)]
    &<= 1 / delta integral_(-infinity)^(+infinity) p(a) d a (2Delta + integral_(a - Delta - delta)^(a + Delta + delta) min(1, p(b) / p(a)) d b) \
    &= 1 / delta integral_(-infinity)^(+infinity) p(a) d a (2Delta + integral_(a - Delta - delta)^(a + Delta + delta) p(b) / p(a) d b) \
    $
    #todo[
        nota, con va bene per p(a) = 0 ma non dovrebbe essere un problema perchè non possiamo essere in un punto t.c. p(a) = 0, ma va dimostrato meglio
    ]

    Ma sappiamo che $integral_(-infinity)^(+infinity) p(b) d b = 1$

    Ora, facendo il limite per $delta -> infinity$:
    ]
]