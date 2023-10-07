
#import "../common-typst/defs.typ": *

#show: common_styles
#show: project.with(
    title: "Relazione Modulo 1",
    authors: (
        (name: "Luca Ciucci", email: "luca.ciucci99@gmail.com"),
    ),
)

#let xtasks = yaml("xtask.yaml");

#outline(indent: 1em)

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
    Il codice Rust corrispondente si trova in #code_ref("mod_1/src/metropolis_1d.rs", line: 37)
    // TODO check link and line
]

== Applicazione ad una distribuzione gaussiana

Per testare l'algoritmo, ho applicato l'algoritmo di Metropolis-Hastings ad una distribuzione gaussiana, in particolare ho campionato la distribuzione $p(x) = N(mu, sigma)$. Come _proposal kernel_, ho utilizzato una distribuzione uniforme $[x - delta \/ 2, x + delta \/ 2]$.

#figure(
    image("img/plots/primo_test_metrogauss.svg", width: 50%),
    caption: [
        Visualizzazione dell'output dell'algoritmo di Metropolis-Hastings applicato ad una distribuzione gaussiana. Sono stati utilizzati i seguenti parametri: $mu = 10$, $sigma = 1$, $x_0 = 0$, $delta = 1$, $N = 1000$ #footnote(raw(xtasks.primo_test_metrogauss, block: false, lang: "sh")).
    ]
) <primo_test_metrogauss>

Come si vede in @primo_test_metrogauss l'algoritmo produce una sequenza di valori che, dopo un certo numero di iterazioni, si stabilizza ed oscilla attorno al valore atteso $mu = 10$. In seguito si analizzerà in dettaglio l'output dell'algoritmo, ma notiamo già che la sequenza di valori prodotta dall'algoritmo è correlata e, visibilmente, sembra rimanere tale anche popo un grande numero di passi

#figure(
    image("img/plots/primo_test_metrogauss-skip.svg", width: 50%),
    caption: [
        Output dell'algoritmo con gli stessi parametri di @primo_test_metrogauss-skip ma con un offset di $10^6$ iterazioni #footnote(raw(xtasks.primo_test_metrogauss-skip, block: false, lang: "sh")).
    ]
) <primo_test_metrogauss-skip>

=== Acceptance

Per valutare l'efficienza dell'algoritmo, è utile calcolare la percentuale di accettazione delle proposte generate dall'algoritmo per capire se il _proposal kernel_ è adeguato. In particolare, se la percentuale di accettazione è troppo bassa, l'algoritmo è inefficiente in quanto genera molte proposte che vengono scartate mentre se è troppo alta, l'algoritmo è comunque inefficiente in quanto genera molte proposte che vengono accettate ed i tempi di autocorrelazione sono alti.

#figure(
    stack(
        dir: ltr,
        stack(image("img/plots/metrogauss-low-delta.svg", width: 40%), [(a)]),
        stack(image("img/plots/metrogauss-high-delta.svg", width: 40%), [(b)]),
    ) + stack(image("img/plots/primo_test_metrogauss-skip.svg", width: 40%), [(c)]),
    caption: [
        Output dell'algoritmo per due diversi $delta$: $delta = 0.1$ in (a)#footnote(raw(xtasks.metrogauss-low-delta, block: false, lang: "sh")) e $delta = 50$ in (b)#footnote(raw(xtasks.metrogauss-high-delta, block: false, lang: "sh")). (c) è corrisponde agli stessi parametri di @primo_test_metrogauss-skip\
        In entrambi i casi si osserva che il tempo di correlazione diventa grande per tali parametri, mentre nel caso (c) in cui $delta = 1$ che è dello stesso ordine di grandezza della deviazione standard della distribuzione target, il tempo di correlazione è molto più basso.
    ],
    // TODO placement: auto,
)

La dipendenza dei tempi di correlazione di $delta$ verrà analizzata in @autocorrelation, per ora possiamo analizzare il rate di accettazione in funzione di $delta$.

#figure(
    stack(
        dir: ltr,
        image("img/plots/metrogauss-acceptance.svg", width: 40%),
        image("img/plots/metrogauss-acceptance-log.svg", width: 40%),
    ),
    caption: [
        Rate di accettazione in funzione di $delta$ in scala lineare (a) e logaritmica (b)
        #footnote(raw(xtasks.metrogauss-acceptance, block: false, lang: "sh"))
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
Possiamo infatti, dati $a$ e $b$ abbiamo, nel nostro caso, la @rho-mh-uniform da cui, dato $a$, il valore di aspettazione di $rho$.  ????
Scriviamo la nostra $A$:
$
A(a, b) = 1 / delta Theta(delta / 2 - abs(b - a))
$
#todo(title:"wrong and incomplete")[
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
Quindi, per grandi $delta$, l'_acceptance rate_ tende a $0$ come $tilde 1\/delta$

=== Autocorrelazione <autocorrelation>

per il calcolo della correlazione, ho usato la teoria descritta in @autocorrelazione-fft.

#todo[
    ...
]

#appendix[Calcolo delle autocorrelazioni tramite FFT] <autocorrelazione-fft>

Per un segnale a tempi discreti $x_t$, la correlazione è definita come:
$
c_k = "cov"(x_i, x_(i + k)) / "cov"(x_i, x_i) = "cov"(x_i, x_(i + k)) / sigma_x^2
$

Possiamo scriverlo come:
$
c_k = E[(x_i - E[x]) (x_(i + k) - E[x])] / E[(x_i - E[x])^2]
$

Dunque, per un campione dato, possiamo stimare l'autocorrelazione come:
$
overline(c)_k = 1 / "var"(x) sum_(i = 0)^(N - k) ((x_i - mu_x) (x_(i + k) - mu_x)) / (N - k)
$

Possiamo dunque scrivere direttamente un algoritmo per il calcolo delle $c_k$ come riportato in @ck-plain.
#algorithm(
    title: [$c_k$ tramite definizione],
    label: "ck-plain",
)[
    #import "@preview/algo:0.3.3": *
    #algo(
        title: "autocorr",
        parameters: ("x", "c"),
    )[
        let $sigma^2$ = var(x)\
        for k in 0..N {#i\
            $c_k <- 0$\
            for i in 0..$N - k$ {#i\
                $c_k <- c_k + (x_i - mu_x) (x_(i + k) - mu_x)$#d\
            }\
            $c_k <- c_k \/ ((N - k) sigma^2)$#d\
        }\
    ]
]

Come possiamo vedere, @ck-plain ha complessità $O(N^2)$ e questo è un problema se vogliamo indagare grandi correlazioni.\
Tuttavia ci aspettiamo che le autocorrelazioni si possano scrivere, in qualche modo, in termini dello spettro del segnale utilizzando gli algoritmi di FFT che possono essere computati in $O(N log(N))$.

Infatti un algoritmo per il calcolo delle autocorrelazioni tramite FFT è mostrato in @ck-fft @autocorr_fft_wikipedia.

#algorithm(
    title: [$c_k$ tramite FFT],
    label: "ck-fft"
)[
    #import "@preview/algo:0.3.3": *
    #algo(
        title: "autocorr_FFT",
        parameters: ("x", "c"),
    )[
        let $F_R (f)$ = $"FFT"[X(t)]$\
        let $S$ = $F_R (f) F_R^*(f)$\
        let $R(tau)$ = $"IFFT"[S(t)]$\
        for k in 0..N #i\
            $c_k <- R(k)$#d\
    ]
]

In letteratura sono descritti altri metodi per la stima efficiente delle $c_k$ senza passare per la FFT. Tali metodi sono specializzati nella stima delle autocorrelazioni ed hanno richieste di memoria minori. Un esempio è dato in @Understanding-Molecular-Simulation-autocorr-cap-4-4-2 .\
Ho scelto di non implementare tale metodo in quanto, vista la sua specializzazione per le simulazioni molecolare, avrebbe richiesto del tempo per essere generalizzato, ho quindi deciso di procedere con la FFT che comunque garantisce $O(N log(N))$. Non avremo problemi di memoria in quanto, per le simulazioni che ho effettuato, $N$ è sempre stato abbastanza piccolo da poter essere gestito facendo copie di array senza problemi.

== Giustificazione matematica

Per la giustificazione dell'utilizzo della FFT nel calcolo delle autocorrelazioni, ho fatto riferimento a @book-back-matter-fourier-analysis.

Il _teorema di correlazione_ afferma che, date due funzioni $f(x, y)$ e $h(x,y)$, si ha che la mutua correlazione (bidimensionale) è:
#todo[
    teorema di correlazione reference
]
$
R_"cross" (x,y) &= integral integral d xi d eta space f(xi, eta) space h^*(xi - x, eta - y) \
&= integral integral d xi d eta space f( xi + x, eta + y) space h^*(xi, eta)
$
per cui definiamo:
$
R_"auto" (x,y) &= integral integral  d xi d eta space f( xi,  eta) space f^*(xi - x, eta - y) \
&= integral integral  d xi d eta space f(xi + x, eta + y) space f^*(xi, eta)
$
Per cui, per il teorema di Wiener-Khintchine:
#todo[
    Wiener-Khintchine reference
]
$
cal(F)[R_"auto" (x,y)] &= cal(F)[integral integral d xi d eta space f(xi, eta) space f^*(xi - x, eta - y)] \
&= abs(F(x,y))^2
$ <wiener-khintchine-2d>
in cui $F(mu, nu) = cal(F)[f(x,y)]$.\
Passando alle variabili discrete, abbiamo @ck-fft.

== Implementazione diretta

Prima di implementare l'algoritmo per le autocorrelazioni tramite FFT, ho deciso di implementare un algoritmo per il calcolo delle autocorrelazioni tramite la definizione e testarlo per avere un punto di riferimento per fare il confronto.

Il codice Rust per il calcolo delle autocorrelazioni tramite la definizione è straightforward ed è riportato in #code_ref("common/src/stat.rs", line: 39)
#todo[
    check link and line
]

Per testare l'algoritmo testato l'algoritmo su una distribuzione gaussiana generata tramite @alg-mh-1d.\
Un esempio di output è riportato in @autocorr_plain.

#figure(
    stack(
        dir: ltr,
        image("img/plots/autocorr_plain.svg", width: 40%),
        image("img/plots/autocorr_plain-log.svg", width: 40%),
    ),
    caption: [
        Esempio #footnote(raw(xtasks.autocorr_plain, block: false, lang: "sh")) di autocorrelazioni calcolate tramite @ck-plain in scala lineare (a) e logaritmica (b)
    ]
) <autocorr_plain>

#note[
    #todo[
        scrivere meglio
    ]
    Non faccio i fit perché è difficile dare una stima degli errori per i ck:
    ad occhio uno potrebbe dire che tanto gli errori sulle ck vanno come $1/sqrt(N-k)$ o qualcosa del genere, ma in realtà è più complicato, ad esempio sappiamo che per piccoli k tende ad 1 e questo non va bene con l'andamento appena descritto. Inoltre C'è correlazione tra i vari c_k in quanto sono fatto su parti (sovrapposte) dello stesso dataset. Quindi, per ora, non ha senso fare i fit.

    Sposta questa nota in @autocorrelation
]

Notiamo che in @autocorr_plain, l'andamento per piccoli $k$ è simil-esponenziale, come aspettato. Inoltre $c_0 = 1$ come aspettato.\

Riducendo il dataset (in quanto l'algoritmo è $O(N^2)$), possiamo vedere l'andamento a grandi $k$ in @autocorr_plain-full.

#figure(
    image("img/plots/autocorr_plain-full.svg", width: 40%),
    caption: [
        Esempio #footnote(raw(xtasks.autocorr_plain-full, block: false, lang: "sh")) di autocorrelazioni calcolate tramite @ck-plain in scala lineare
    ]
) <autocorr_plain-full>

Prenderemo dunque questa implementazione come quella di riferimento.

== Implementazione tramite FFT

Per l'implementazione ho utilizzato la libreria `rustfft`@rustfft che permette di calcolare la FFT in $O(N log(N))$.

Per l'implementazione possiamo considerare @wiener-khintchine-2d su un dominio finito e discretizzato che ci permetterebbe, tramite @ck-fft, di calcolare
$
tilde(c)_k eq.def sum_(i = 1)^N delta x_i space delta x_((i + k) mod N)
$ <c_tilde_k>
dove $delta x_i = x_i - mu_x$ e $mu_x$ è la media del dataset.\
Ma $tilde(c)_k$ non sono le $c_k$ che ci interessano: sono le autocorrelazioni per lo stesso segnale ma periodicizzato.\

Possiamo allora riprendere @c_tilde_k e fare un _padding_:
$
delta x_i prime = cases(
    delta x_i & #[se] i <= N,
    0 & #[altrimenti]
)
$
In questo modo è ovvio che
$
tilde(c)_k prime &eq.def sum_(i = 1)^N delta x_i prime space delta x prime _((i + k) mod N) \
&= sum_(i = 1)^(N - k) delta x_i prime space delta x prime _(i + k) \
&= sum_(i = 1)^(N - k) delta x_i space delta x _(i + k) \
&= c_k
$

Possiamo allora scrivere l'algoritmo per il calcolo delle autocorrelazioni tramite FFT come @ck-fft-1d, il cui codice Rust è riportato in #code_ref("mod_1/src/stat.rs", line: 59)
#todo[
    check link and line
]
#algorithm(
    title: [$c_k$ tramite FFT],
    label: "ck-fft-1d"
)[
    #import "@preview/algo:0.3.3": *
    #algo(
        title: "autocorr_FFT",
        parameters: ("x", "c"),
    )[
        let x = concatenate(x, [0; len(x)]) #comment[padding]\
        let x $<-$ fft(x);\
        let x $<-$ x\* #math.dot x;\
        let x $<-$ ifft(x);\
        #comment[counting factor]
        for k in 0..N #i\
            $c_k <- c_k / (N - k)$\
            #comment[normalization]
            $c_k <- c_k \/ c_0$#d\
    ]
]

Possiamo notare in @confronto-ck-plain-fft che le autocorrelazioni fornite dai due algoritmi sono identiche, infatti la differenza massima tra i due metodi è di $1.4 dot 10^(-13)$ che è probabilmente dovuta ad errori di arrotondamento.
#note[
    Non ho indagato ulteriormente sulla natura di questa differenza in quanto non è rilevante per il progetto, ma potrebbe essere interessante capire da cosa è dovuta e se è possibile evitarla.
]

#figure(
    stack(
        dir: ltr,
        image("img/plots/autocorr_plain-full.svg", width: 40%),
        image("img/plots/autocorr_fft-full.svg", width: 40%),
    ),
    caption: [
        Esempio di autocorrelazioni calcolate tramite @ck-plain (a) e @ck-fft-1d (b) #footnote(raw(xtasks.autocorr_fft-full, block: false, lang: "sh")) in scala lineare. Le differenza massima tra i due metodi è di $1.4 dot 10^(-13)$.
    ]
) <confronto-ck-plain-fft>

== Note sulla definizione delle $c_k$

#bibliography("bibliography.yaml")