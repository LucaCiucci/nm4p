#import "../../common-typst/defs.typ": *
#let xtasks = yaml("/mod_1/xtask.yaml")

#appendix(label: "tau_int-vs-tau_exp")[$tau_"int"$ vs $tau_"exp"$][

    La definizione di $tau_"int"$ data in @tau-int-basic è stata scelta in modo tale che, nel caso di autocorrelazioni esponenziale, per grandi tempi di autocorrelazione si ha $tau_"int" approx tau_"exp"$. In tal modo, stimando $tau_"int"$ possiamo avere un'idea intuitiva dei tempi caratteristici del tempo di autocorrelazione caratteristico del sistema.\

    E' importante notare che, anche nel caso di autocorrelazioni esponenziali, $tau_"int"$ non è il tempo di autocorrelazione, ma è un valore generalmente simile.\
    Infatti, secondo @tau-int-basic abbiamo che:
    $
    tau_"int" &= sum_(k = 1)^N c_k = sum_(k = 1)^N e^(-k \/ tau_"exp")\
    &approx sum_(k = 1)^N e^(-k \/ tau_"exp") = e^(-k \/ tau_"exp") / (1 - e^(-k \/ tau_"exp"))
    $ <tau_int_of_tau_exp>
    dunque, la correzione è:
    $
    tau_"int" / tau_"exp" = e^(-k \/ tau_"exp") / (tau_"exp" (1 - e^(-k \/ tau_"exp")))
    $ <tau_int_over_tau_exp>
    Per cui, ad esempio si ha:
    #let tau_exp = 100
    #let rounding = 1000
    $
    cases(
        tau_"exp" = #tau_exp,
        tau_"int" approx.eq #(calc.round(calc.exp(-1 / tau_exp) / (1 - calc.exp(-1 / tau_exp)) * rounding) / rounding),
        tau_"int" \/ tau_"exp" approx.eq #(calc.round(calc.exp(-1 / tau_exp) / (1 - calc.exp(-1 / tau_exp)) * rounding * 10 / tau_exp) / (rounding * 10)),
    )
    $

    #warning[$ tau_"int" eq.not tau_"exp" $]
]