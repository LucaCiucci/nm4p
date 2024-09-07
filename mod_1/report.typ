
#import "../common-typst/defs.typ": *

#show: common_styles
#show: project.with(
    title: "Relazione Modulo 1",
    authors: (
        (name: "Luca Ciucci", email: "luca.ciucci99@gmail.com"),
    ),
)

#outline(indent: 1em)

= Introduzione

In questo progetto, mi sono occupato dell'implementazione e l'applicazione dell'algoritmo di metropolis nel caso monodimensionale e nell'applicazione al modello di Ising 2D.

= Algoritmo di Metropolis-Hastings <the-metropolis-hastings-algorithm>

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

#note[
    This section is intended to master the statistics behind the Metropolis-Hastings algorithm.
]

Mi sono occupato dell'implementazione dell'algoritmo di Metropolis nel caso monodimensionale, in particolare sulla stima delle correlazioni e degli errori.

@alg-mh fornisce una definizione operativa, pertanto è risultato naturale scrivere il seguente algoritmo:

#import "@preview/algo:0.3.3"
#algorithm(
    title: [Pseudo-codice per Metropolis-Hastings],
    label: "alg-mh-1d"
)[
    #let i = algo.i;
    #let d = algo.d;
    #let comment = algo.comment;
    #algo.algo(
        title: "MH1D_step",
        parameters: ("p", "x", "proposal_kernel",),
    )[
        (proposal, proposal_ratio) $<-$ proposal_kernel(x)\
        $rho$ $<-$ $min(1, p("proposal") / p(x) "proposal_ratio")$\
        accept $<-$ random() < $rho$\
        if (accept)#i\
            x $<-$ proposal#d\
    ]
    `proposal_kernel` genera una proposta e l'inverso del rapporto tra la probabilità della proposta e del processo inverso ($A(b -> q) / A(a -> b)$)
    #todo[
        controlla il rapporto
    ]
    Il codice Rust corrispondente si trova in #code_ref("/mod_1/src/metropolis_1d.rs", line: "pub fn step")
    // TODO check link and line
]

== Applicazione ad una distribuzione gaussiana

Per testare l'algoritmo, ho applicato l'algoritmo di Metropolis-Hastings ad una distribuzione gaussiana, in particolare ho campionato la distribuzione $p(x) = N(mu, sigma)$. Come _proposal kernel_, ho utilizzato una distribuzione uniforme $[x - delta \/ 2, x + delta \/ 2]$.

#figure(
    image("img/plots/primo_test_metrogauss.svg", width: 50%),
    caption: [
        Visualizzazione dell'output dell'algoritmo di Metropolis-Hastings applicato ad una distribuzione gaussiana. Sono stati utilizzati i seguenti parametri: $mu = 10$, $sigma = 1$, $x_0 = 0$, $delta = 1$, $N = 1000$ #footnote(mod_1-command("run primo_test_metrogauss")).
    ]
) <primo_test_metrogauss>

Come si vede in @primo_test_metrogauss l'algoritmo produce una sequenza di valori che, dopo un certo numero di iterazioni, si stabilizza ed oscilla attorno al valore atteso $mu = 10$. In seguito si analizzerà in dettaglio l'output dell'algoritmo, ma notiamo già che la sequenza di valori prodotta dall'algoritmo è correlata e, visibilmente, sembra rimanere tale anche popo un grande numero di passi

#figure(
    image("img/plots/primo_test_metrogauss-skip.svg", width: 50%),
    caption: [
        Output dell'algoritmo con gli stessi parametri di @primo_test_metrogauss-skip ma con un offset di $10^6$ iterazioni #footnote(mod_1-command("run primo_test_metrogauss-skip")).
    ]
) <primo_test_metrogauss-skip>

=== Acceptance

Per valutare l'efficienza dell'algoritmo, è utile calcolare la percentuale di accettazione delle proposte generate dall'algoritmo per capire se il _proposal kernel_ è adeguato. In particolare, se la percentuale di accettazione è troppo bassa, l'algoritmo è inefficiente in quanto genera molte proposte che vengono scartate mentre se è troppo alta, l'algoritmo è comunque inefficiente in quanto genera molte proposte che vengono accettate ed i tempi di autocorrelazione sono alti.

#figure(
    stack(
        dir: ltr,
        stack(image("img/plots/metrogauss-low-delta.svg", width: 50%), [(a)]),
        stack(image("img/plots/metrogauss-high-delta.svg", width: 50%), [(b)]),
    ) + stack(image("img/plots/primo_test_metrogauss-skip.svg", width: 50%), [(c)]),
    caption: [
        Output dell'algoritmo per due diversi $delta$: $delta = 0.1$ in (a)#footnote(mod_1-command("run metrogauss-low-delta")) e $delta = 50$ in (b)#footnote(mod_1-command("run metrogauss-high-delta")). (c) è corrisponde agli stessi parametri di @primo_test_metrogauss-skip\
        In entrambi i casi si osserva che il tempo di correlazione diventa grande per tali parametri, mentre nel caso (c) in cui $delta = 1$ che è dello stesso ordine di grandezza della deviazione standard della distribuzione target, il tempo di correlazione è molto più basso.
    ],
    // TODO placement: auto,
)

La dipendenza dei tempi di correlazione di $delta$ verrà analizzata in @autocorrelation, per ora possiamo analizzare il rate di accettazione in funzione di $delta$.

#figure(
    stack(
        dir: ltr,
        image("img/plots/metrogauss-acceptance.svg", width: 50%),
        image("img/plots/metrogauss-acceptance-log.svg", width: 50%),
    ),
    caption: [
        Rate di accettazione in funzione di $delta$ in scala lineare (a) e logaritmica (b)
        #footnote(mod_1-command("run metrogauss-acceptance"))
    ]
)

Osserviamo che, per piccoli $delta$, l'_acceptance rate_ tende all'unità, infatti, dalla @rho-mh vediamo:
$
rho(a, b) = min(1, p(b) / p(a) A(b -> q) / A(a -> b)) = min(1, p(b) / p(a))
$ <rho-mh-uniform>
in quanto la distribuzione è uniforme. Facendo il limite per $delta -> 0$, abbiamo che $p(b) / p(a) -> 1$ (assumendo $p$ lipschitziana) e quindi, in questo caso:
$
lim_(delta -> 0) rho(a, b) -> 1 space
$.
Cioè l'algoritmo accetta _quasi_-sempre le proposte generate dal _proposal kernel_.
#todo[
    verifica la definizione di quasi sempre
]

Per $delta$ grandi, invece, l'_acceptance rate_ tende a $0$ in quanto il _proposal kernel_ genera proposte che sono molto lontane dal valore atteso e quindi la probabilità di accettazione è molto bassa.\

Per grandi $delta$, l'_acceptance rate_ tende a $0$ come $tilde 1\/delta$, vedi @andamento_1_delta. Questo è dovuto al fatto che, per grandi $delta$, il _proposal kernel_ genera proposte che sono molto lontane dal valore atteso e quindi la probabilità di accettazione è molto bassa.

#warning[
    Non ho eseguito alcun fit o verifica empirica di tale andamento in quanto è irrilevante per il lavoro seguente, ma la giustificazione formale è riportata in @andamento_1_delta.
]

#todo[
    scrivi che metodi adattivi che cambiano la delta per mantenere il rate di acceptance buono non vanno bene perché la catena non sarebbe più una catena di markov in cui la W è costante
]

=== Autocorrelazione <autocorrelation>

Per il calcolo della correlazione, ho usato la teoria descritta in @autocorrelazione-fft.

Un tipico grafico delle autocorrelazioni per l'algoritmo di metropolis applicato applicato alla distribuzione gaussiana è riportato in @autocorr-typical dove possiamo notare la parte iniziale dall'andamento esponenziale ed una coda che oscilla attorno a $0$.

#figure(
    image("img/plots/autocorr_fft-typical.svg", width: 50%),
    caption: [
        Esempio di autocorrelazioni calcolate tramite @ck-fft-1d #footnote(mod_1-command("run autocorr_fft-typical")).
    ]
) <autocorr-typical>

Non ho eseguito alcun fit per stimare il tempo di correlazione in quanto è difficile dare una stima degli errori per i $c_k$: si potrebbe pensare di fare un fit con un peso dei vari punti pari a $sqrt(N - k)$, ma questo non è corretto e possiamo vederlo notando che $c_0 = 1$. Questo perché i vari $c_k$ sono correlati fra loro e dunque l'esecuzione di un fit sarebbe arduo.\
#todo[
    giustifica $sqrt(N - k)$
]
Consideriamo ad esempio l'algoritmo di Levenberg-Marquardt @levenberg-marquardt che minimizza una funzione $chi^2$: per eseguire il fit dovremmo popolare la matrice $W$ che non è diagonale se i punti sono correlati. Consideriamo ad esempio di dover calcolare $"cov"(c_1, c_2)$, usando @def_ck_est:
$
//"cov"(c_1, c_2) =  E[(sum_(i = 1)^(N - 1) ((x_i - mu_x) (x_(i + k) - mu_x)) / (N - k) - E[c_1]) \ (sum_(i = 2)^(N - 2) ((x_i - mu_x) (x_(i + k) - mu_x)) / (N - k) - E[c_2])]
"cov"(c_1, c_2) = E[(c_1 - E[c_1])(c_2 - E[c_2])] = E[c_1 c_2] - E[c_1] E[c_2] \
= E[(sum_(i = 1)^(N - 1) ((x_i - mu_x) (x_(i + k) - mu_x)) / (N - 1))(sum_(i = 2)^(N - 2) ((x_i - mu_x) (x_(i + k) - mu_x)) / (N - 2))] - E[c_1] E[c_2] \
= (N-2)/(N-1)E[c_2^2] + E[c_2(((x_1 - mu_x) (x_2 - mu_x)) / (N - 1) + ((x_(N-k) - mu_x) (x_(N - k - 1) - mu_x)) / (N - 2))] - E[c_1] E[c_2] \
$ <cov-c1-c2>
Se facessimo ciecamente un fit ai minimi degli scarti quadratici, è come se stessimo considerando tutta questa quantità nulla, cosa non vera in generale, mentre non è banale da calcolare tali termini e farlo per tutte le coppie possibile ($O(N^2)$ di valutazioni di tale quantità, costo $O(N^3)$). Per tale motivo ho deciso di non eseguire alcun fit per stimare il tempo di correlazione tramite le autocorrelazioni.

#note[
    In @cov-c1-c2 potremmo approssimare
    $
    (N-k_2)/(N-k_1)E[c_(k_2)^2] - E[c_(k_1)] E[c_k_(2)] = "var"(c_k)
    $
    per $k_2 - k_1$ piccolo che è il caso problematico, ma questo non risolve il problema dell'altro termine che non è banale e richiede una sommatoria di ordine $k_2 - k_1$.
]

#include "appendixes/iat.typ"
#include "appendixes/1_delta_trend.typ"
#include "appendixes/autocorr_fft.typ"
#include "appendixes/tau_int-vs-tau_exp.typ"
#include "appendixes/cubic-interpolation.typ"
#include "appendixes/reweighting.typ"
#include "appendixes/ad.typ"
#include "appendixes/ADMC.typ"

= Codebase

The repository can be found at https://github.com/LucaCiucci/nm4p, where every result and plot can be reproduced by running ```sh cargo xtask```, but it might take several hours to complete.

#bibliography("bibliography.yaml")