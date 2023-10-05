
#import "../common-typst/defs.typ": *

#show: common_styles
#show: project.with(
    title: "Relazione Modulo 1",
    authors: (
        (name: "Luca Ciucci", email: "luca.ciucci99@gmail.com"),
    ),
)

#outline()

= Introduzione

In questo progetto, mi sono occupato dell'implementazione e l'applicazione dell'algoritmo di metropolis nel caso monodimensionale e nell'applicazione al modello di Ising 2D.

= Algoritmo di Metropolis-Hastings

L'algoritmo di metropolis è permette di campionare distribuzioni di probabilità tramite una catena di Markov. E' un approccio indiretto per le simulazioni di distribuzioni complesse che permetter di superare il problema del "course of dimensionality" incontrato nelle simulazioni dirette.

L'algoritmo di campionamento in questione fa parte dei Markov Chain Monte Carlo (MCMC) methods
Per generare una catena di markov associata and una distribuzione target $p(bold(x))$, si utilizza il seguente algoritmo iterativo @metropolis-orig @metropolis-hastings:

#algorithm(
    title: [Metropolis-Hastings],
    label: "alg-mh"
)[
    Sia $p: Omega -> RR$ la distribuzione target, con $Omega$ lo spazio degli stati.\
    Iterativamente, dato $bold(x)_i in Omega$:
    + si genera $bold(x)_t in Omega$ (test) da una distribuzione di probabilità $A(bold(x)_t | bold(x)_i) equiv A_(bold(x)_t bold(x)_i) equiv A(bold(x)_i -> bold(x)_t)$ (_proposal kernel_) // TODO scegli uno di questi, metti gli altri negli appunti
    + si definisce:
      $
      rho(a, b) = min(1, p(b) / p(a) A(b -> q) / A(a -> b))
      $ <rho-mh>
    + $
      bold(x)_(i+1) = cases(
        bold(x)_t & #[con probabilità] rho(bold(x)_i, bold(x)_t),
        bold(x)_i & #[con probabilità] 1 - rho(bold(x)_i, bold(x)_t)
      )
      $
    #todo[
        controlla il rapporto
    ]
]

#todo[
    dire quando la catena di @alg-mh converge alla distribuzione target
]

#todo[
    ...
]

= Algoritmo di Metropolis-Hastings nel caso monodimensionale

Mi sono occupato dell'implementazione dell'algoritmo di Metropolis nel caso monodimensionale, in particolare sulla stima delle correlazioni e degli errori.

@alg-mh fornisce una definizione operativa, pertanto è risultato naturale scrivere il seguente algoritmo:

#import "@preview/algo:0.3.3"
#algorithm(title: [Pseudo-codice per Metropolis-Hastings])[
    #let i = algo.i;
    #let d = algo.d;
    #let comment = algo.comment;
    #algo.algo(
        title: "MH1D_step",
        parameters: ("p", "x", "proposal_kernel",),
    )[
        (proposal, proposal_ratio) $<-$ proposal_kernel(x)\
        rho $<-$ $min(1, p("proposal") / p(x) "proposal_ratio")$\
        accept $<-$ random() < rho\
        if (accept)#i\
            x $<-$ proposal#d\
    ]
    `proposal_kernel` genera una proposta e l'inverso del rapporto tra la probabilità della proposta e del processo inverso ($A(b -> q) / A(a -> b)$)
    #todo[
        controlla il rapporto
    ]
    Il codice Rust corrispondente si trova in #code_ref("mod_1/", line: 1)
]

=== Implementazione

#figure(
    image("img/a.svg", width: 50%),
    caption: [Ciao a tutti]
)

#bibliography("bibliography.yaml")