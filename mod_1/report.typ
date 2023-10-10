
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
        Esempio di autocorrelazioni calcolate tramite @ck-fft-1d #footnote(raw(xtasks.autocorr_fft-typical, block: false, lang: "sh")).
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

=== Tempo di autocorrelazione integrato <tempo-autocorr-integrato>

Siamo solitamente interessati a stimare valori di aspettazione con delle medie campionarie, per questo è necessario associare un'incertezza statisticamente significativa a tali valori.

Consideriamo
$
overline(x) = 1 / N sum_(i = 1)^N x_i
$
vogliamo conoscere l'incertezza su questa stima $sigma_overline(x)$ che si può dimostrare #footnote(todo[reference]) essere @autocorr-daniel @ensemble-sampler-section-5:
$
sigma_overline(x)^2 = 1/N sigma_x^2 (1 + 2 tau_"int")
$ <var-of-mean-corrected>
con
$
tau_"int" = sum_(k = 1)^N c_k
$ <tau-int-basic>

But, following @Berg-lecturenotes-7-MCMC-III-p7 and @intro-MCMC-berg we could use:
$
tau_"int" = sum_(k = 1)^N (1 - k/N) c_k
$ <tau-int-corrected>
#todo[
    check why, also find a good reference for this
]
It is trivial to show that, for $N -> infinity$ and $k << N$, @tau-int-corrected is equivalent to @tau-int-basic.

Per analizzare il comportamento di $tau_"int"$, definiamo:
$
tau_"int" (M) = sum_(k = 1)^M (1 - k/N) c_k
$

#figure(
    image("img/plots/autocorr-int.svg", width: 40%),
    caption: [
        Tempo di autocorrelazione integrato in funzione di $M$ #footnote(raw(xtasks.autocorr-int, block: false, lang: "sh")).
    ]
)

#todo[
    Metti anche una figura con delle barre di varianza come in @intro-MCMC-berg fig 10
]

Come vediamo, il tempo di autocorrelazione integrato cresce linearmente con $M$ per poi sembrar stabilizzarsi attorno ad un valore. Tuttavia, indagando su tutto lo spettro delle $tau_"int" (M)$:
#figure(
    stack(
        dir: ltr,
        image("img/plots/autocorr-int-full.svg", width: 40%),
        image("img/plots/autocorr-int-full-corrected.svg", width: 40%),
    ),
    caption: [
        Tempo di autocorrelazione integrato in funzione di $M$ per $M = 1..N$ tramite la definizione @tau-int-basic (a) #footnote(raw(xtasks.autocorr-int-full, block: false, lang: "sh")) e @tau-int-corrected (b) #footnote(raw(xtasks.autocorr-int-full-corrected, block: false, lang: "sh")).
    ]
) <autocorr-int-full>
Come si vede da @autocorr-int-full, per entrambi le definizioni, il tempo di autocorrelazione integrato non si stabilizza per grandi $M$. Si potrebbe pensare di fare un fit diminuendo il peso dei punti con $M$ grande, ma questo ha problemi simili ad un eventuale fit delle autocorrelazioni (vedi @autocorrelation) ed inoltre non è vero, in generale, che le $c_k$ siano dominate da un singolo andamento esponenziale in quanto possono essere presenti più scale di correlazione, e noi non siamo interessati a nessuna di queste, neanche $tau_"exp"$.

In letteratura sono stati presentati diversi metodi per la stima di un buon $M$. Ad esempio in @mcm-stat-mech-sokal @autocorr-daniel si suggerisce di prendere $M$ tale che $M >= C tau_"int"(M)$ con $C tilde 5$, e tale procedura funziona bene per $N gt.approx 1000 tau_"int"$. @autocorr-daniel suggerisce che tale metodo funzioni bene anche per $N gt.approx 50 tau_"int"$ nel caso in cui si prendano delle serie parallele per ridurre la varianza. Quest'ultimo non è tuttavia il nostro caso di utilizzo in quanto per generare delle serie parallele è necessario avere lo stato iniziale distribuito come la distribuzione target, che però è il problema che stiamo cercando di risolvere, oppure aspettare che ogni serie "termalizzi", che risulterebbe sub-ottimale.

Un altro metodo che mi è venuto in mente è quello di prendere il secondo punto delle correlazioni $c_0$ e approssimare la derivata in $0$ come $c_1 - c_0$ e quindi stimare $tau_"int" = 1 / (c_1 - c_0)$, ma questo metodo non è corretto in quanto non tiene conto del fatto che possono esserci diversi andamenti esponenziali.
#todo[
    $tau_"int" = 1 / (c_1 - c_0)$ da controllare
]

Richiedo allora un algoritmo che:
+ sia semplice da implementare: vogliamo solo una stima approssimata di $tau_"int"$, che ci servirà solo avere un ordine di grandezza da applicare all'algoritmo di binning (vedi @binning)
+ non tenga conto solamente dei primi punti: questi sono dominati dagli andamenti esponenziali più rapidi che hanno derivata maggiore
+ non dia troppo peso ai punti con $M gt.approx tau_"int"$ grande: le cui oscillazioni sono dominate dal "rumore"

Non ho trovato un algoritmo che soddisfi queste proprietà, per cui ho deciso di implementare un algoritmo "euristico" ??? @alg-estimate-M.

#algorithm(
    title: [Stima di $M$],
    label: "alg-estimate-M",
)[
    + Calcola le ${c_k}$
    + trova il primo $m$ tale che $c_m < 0$
    + $M = m$
]

@alg-estimate-M si basa sul fatto che $c_k$ abbia ha oscillazioni con correlazioni con durata dello stesso ordine di grandezza di quelle del dataset.
#todo[
    mostrare perché
]
Per cui ci aspettiamo che, quando l'andamento esponenziale più lento si avvicina allo zero, le oscillazioni di $c_k$ siano dominate dal rumore e toccheranno lo zero entro un tempo dello stesso ordine di grandezza del tempo di correlazione integrato. Qualora questo non avvenga, le autocorrelazioni sono tutte positive e dunque il dataset non è sufficientemente grande per stimare $tau_"int"$. In tal caso, si può provare ad aumentare il dataset e ripetere l'algoritmo.

#figure(
    stack(
        dir: ltr,
        stack(image("img/plots/autocorr-int-algo.svg", width: 40%), [(a)]),
        stack(image("img/plots/autocorr-int-algo-int.svg", width: 40%), [(b)]),
    ),
    caption: [
        Esempio dell'output dell'algoritmo @alg-estimate-M applicato ad una serie di autocorrelazioni proveniente dall'algoritmo di metropolis su distribuzione gaussiana #footnote(raw(xtasks.autocorr-int-algo, block: false, lang: "sh")). La linea rossa rappresenta $M$. In (a) sono riportati i $c_k$ mentre in (b) i corrispondenti $tau_"int" (M)$.
    ]
) <autocorr-int-algo-out>

Tale algoritmo non richiede lunghezze del dataset molto maggiori del tempo di autocorrelazione integrato come in @mcm-stat-mech-sokal, ma è comunque necessario che il dataset sia sufficientemente grande per stimare $M$.

#todo[
    Fare qualche controllo tipo che se $M > N / 10$ o qualcosa del genere, l'algoritmo da errore perché il dataset non è sufficiente.
]

L'algoritmo finale è dunque semplicemente @alg-estimate-tau-int
#algorithm(
    title: [Stima di $tau_"int"$],
    label: "alg-estimate-tau-int",
)[
    + Stima $M$ con @alg-estimate-M
    + $overline(tau)_"int" = c_M$
]

Possiamo poi pensare di rendere l'algoritmo più robusto agendo sulla derivata di $c_k$ in $0$ per stimare $M$ anziché sul valore di $c_k$ stesso, come mostrato in @alg-estimate-M-deriv.
#algorithm(
    title: [Stima di $M$ tramite derivata delle $c_k$],
    label: "alg-estimate-M-deriv",
)[
    + Calcola le ${c_k}$
    + trova il primo $m$ tale che $c_m < c_(m + 1)$
    + $M = m$
]

#figure(
    stack(
        dir: ltr,
        stack(image("img/plots/autocorr-int-algo-deriv.svg", width: 40%), [(a)]),
        stack(image("img/plots/autocorr-int-algo-deriv-int.svg", width: 40%), [(b)]),
    ),
    caption: [
        Esempio dell'output dell'algoritmo @alg-estimate-M-deriv applicato come in @autocorr-int-algo-out #footnote(raw(xtasks.autocorr-int-algo-deriv, block: false, lang: "sh")). La linea rossa rappresenta $M$. In (a) sono riportati i $c_k$ mentre in (b) i corrispondenti $tau_"int" (M)$.
    ]
) <autocorr-int-algo-out-deriv>

Da @autocorr-int-algo-out-deriv sembra che l'algoritmo @alg-estimate-M-deriv sia più "corretto" di @alg-estimate-M in figura @autocorr-int-algo-out ed anche più stabile al variare del seme e della lunghezza della catena di markov.\
Per verificarlo, proviamo a vedere gli andamenti di $tau_"int" (M)$ per entrambi gli algoritmi al variare di $N$.

#note[
    Questo miglioramento è solo apparente ed è dovuto principalmente a 2 fattori:
    + la varianza è più piccola
    + la convergenza è più lenta e quindi sembra che l'algoritmo sia più stabile per N in un certo intervallo
    
]

#figure(
    image("img/plots/autocorr-int-finder-tau_int-vs-iter.svg", width: 40%),
    caption: [
        Andamento dei tempi di autocorrelazione integrati in funzione di $N$ per entrambi gli algoritmi #footnote(raw(xtasks.autocorr-int-finder-tau_int-vs-iter, block: false, lang: "sh")). In nero è riportato il risultato e la varianza con $M$ calcolato con@alg-estimate-M mentre in rosso @alg-estimate-M-deriv.
    ]
) <autocorr-int-finder-tau_int-vs-iter>

Da @autocorr-int-finder-tau_int-vs-iter osserviamo che entrambi gli algoritmi sembrano tendere ad uno stesso valore, che è quello che ci aspettiamo. Inoltre, @alg-estimate-M-deriv, pur avendo una varianza minore, converge più lentamente, sia per $N$ intermedi che per $N$ grandi, per questo motivo in tutte le analisi successive ho usato @alg-estimate-M per cui è richiesto un $N$ minore prima di essere "ragionevolmente"!!!!! alla convergenza.

Notiamo inoltre, dai grafici precedenti @autocorr-int-algo-out e @autocorr-int-algo-out-deriv, che gli algoritmi fanno pressappoco ciò che faremmo "ad occhio", quindi userò @alg-estimate-tau-int associato ad @alg-estimate-M per stimare $tau_"int"$ anziché farlo manualmente onde evitare errori umani.
Per quanto riguarda la non correttezza della stima per $N$ non sufficientemente grandi, notiamo che si avrebbe lo stesso problema con una selezione manuale di $M$: manualmente prenderemmo un $M$ tale che il grafico di $tau_"int"(M)$ si "appiattisca", ma questo è esattamente quello che sta facendo l'algoritmo e dunque la problematica è esattamente la stessa.

Da @autocorr-int-finder-tau_int-vs-iter possiamo inoltre dire che l'algoritmo fornisce stime ragionevolmente valide per $N gt.approx 1000 tau_"int"$, come nel caso del metodo di Sokal @mcm-stat-mech-sokal, anche se per i nostri scopi anche valori $N gt.approx 100 tau_"int"$ (o probabilmente anche meno) sarebbero sufficienti. Per non perderci in dettagli implementativi, ho fatto in modo che l'algoritmo semplicemente non restituisca nulla in output (rappresentando un errore di utilizzo) se $N < 100 tau_"int"$.\
Inoltre a differenza del metodo di Sokal, non è richiesta alcuna costante arbitraria $C$.

Ho dunque deciso di proseguire utilizzando tale algoritmo per la stima di $tau_"int"$, il cui corrispondente codice si trova in #code_ref("common/src/stat.rs", line: 183).
#todo[
    check link and line
]

Con gli strumenti appena descritti, possiamo stimare il tempo di autocorrelazione integrato per l'algoritmo di metropolis applicato alla distribuzione gaussiana vs accettazione. Un esempio di tale stima è riportato in @metrogauss-tau_vs_acc.
#figure(
    image("img/plots/metrogauss-tau_vs_acc.svg", width: 40%),
    caption: [
        Tempo di autocorrelazione integrato in funzione del rate di accettazione per l'algoritmo di metropolis applicato alla distribuzione gaussiana #footnote(raw(xtasks.metrogauss-tau_vs_acc, block: false, lang: "sh")).
    ]
) <metrogauss-tau_vs_acc>

#todo[
    alcune osservazioni
]

== Binning (aka Blocking) <binning>

#todo[
    da qualche parte scrivere:\
    la correzione tramite tauint @var-of-mean-corrected è solo un approssimazione, per questo usare la definizione porta ad un risultato sbagliato. Infatti, rivedi le formule con la matrice quadrata, effetti di bordo etc.
]

Come visto in @tempo-autocorr-integrato, per stimare la varianza associata alla madia campionaria in un set di dati correlati temporalmente, è possibile necessario stimare il tempo di autocorrelazione integrato $tau_"int"$ tramite @var-of-mean-corrected, che è quello che abbiamo fatto nella sezione precedente.\
Tuttavia @alg-estimate-tau-int non coincide con la definizione formale di $tau_"int"$, che è solo un'approssimazione in ogni caso (non ha significato pratico). Abbiamo visto inoltre che @alg-estimate-tau-int non è un buon stimatore per $tau_"int"$ per $N lt.approx 1000 tau_"int"$, e comunque ha una varianza relativamente alta.\
Per questo motivo, è necessario utilizzare un metodo che permetta di stimare la varianza di una media campionaria in un set di dati correlati temporalmente, ed una possibilità è il metodo del binning @intro-MCMC-berg (o blocking).

Il metodo del binning consiste nel dividere il dataset in blocchi di lunghezza $k$ e calcolare la media campionaria di ogni blocco:
$
x_i^k = 1 / k sum_(j = 1)^(k) x_(i k + j)
$
E abbiamo che (@intro-MCMC-berg #sym.section 10.2) per $k >> tau_"int"$:
+ sono distribuiti in modo approssimativamente gaussiano: questo per il teorema del limite centrale
+ le correlazioni trai i bins tendono a zero come $tilde 1/k^2$
#todo[
    controlla $tilde 1/k^2$: non c'è scritto in @intro-MCMC-berg ma immagino che sia così. Infatti la parte di dati correlati è quella ai bordi dei blocchi, che è di lunghezza $tilde tau_"int"$ e sulla media dei blocchi conta come $tilde tau_"int" \/ k$, ma poi quando la inserisco la covarianza $"cov"(x_i^k, x_i^(k+1))$ è bilineare quindi penso che esca fuori $1/k^2$.
]
Dunque possiamo stimare (@intro-MCMC-berg):
$
1 + 2 tau_"int" = lim_(k -> infinity) ("var"(x_i^k) / "var"(x_i))
$
dove $"var"(x_i)$ è l'estimatore:
$
"var"(x_i) = 1 / (N - 1) sum_(j = 1)^(N) (x_j - overline(x))^2
$
#todo[
    questa va scritta prima e fai una reference al codice
]
Cioè, inserendolo nella @var-of-mean-corrected, possiamo semplicemente stimare:
$
sigma_overline(x)^2 = lim_(k -> infinity) "var"(x_i^k) / k
$
Che è quello che ci interessava.

#appendix[Andamento $1\/delta$] <andamento_1_delta>

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

#appendix[Calcolo delle autocorrelazioni tramite FFT] <autocorrelazione-fft>

Per un segnale a tempi discreti $x_t$, la correlazione è definita come:
$
c_k = "cov"(x_i, x_(i + k)) / "cov"(x_i, x_i) = "cov"(x_i, x_(i + k)) / sigma_x^2
$ <def_ck>

Possiamo scriverlo come:
$
c_k = E[(x_i - E[x]) (x_(i + k) - E[x])] / E[(x_i - E[x])^2]
$

Dunque, per un campione dato, possiamo stimare l'autocorrelazione come:
$
overline(c)_k = 1 / "var"(x) sum_(i = 0)^(N - k) ((x_i - mu_x) (x_(i + k) - mu_x)) / (N - k)
$ <def_ck_est>

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

Possiamo allora riprendere @c_tilde_k e fare un _zero padding_:
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

Possiamo allora scrivere l'algoritmo per il calcolo delle autocorrelazioni tramite FFT come @ck-fft-1d, il cui codice Rust è riportato in #code_ref("common/src/stat.rs", line: 59)
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

#note[
    Ho lasciato considerato la trattazione bidimensionale in quanto potrebbe tornare utile successivamente nell modello si Ising.
    #todo[
        ???
    ]
]

== Note sulla definizione delle $c_k$

Si potrebbe pensare che la definizione @def_ck possa essere modificata:
$
c_k = "cov"(x_i, x_(i + k)) / "cov"(x_i, x_i) --> "cov"(x_i, x_(i + k)) / (sigma_(x_i) sigma_(x_(i+k)))
$
cambiando la media con la media campionaria dei due pezzi del dataset, anziché sull'intero campione e facendo la stessa cosa per la varianza.\
Cioè, considerando che le correlazioni sono fatte su due set separati:
$
A_(i,k) &= x_i\
B_(i,k) &= x_(i + k)\
"con" i &< N - k
$
Allora risulta, per definizione di correlazione:
$
c_k = sigma_(A_(i,k), B_(i,k)) / (sigma_(A_(i,k)) sigma_(B_(i,k)))
$ <ck_modified>
L'implementazione algoritmica di tale definizione è meno immediata: utilizzando direttamente @ck_modified si avrebbe un algoritmo $O(N^3)$ e questo risulterebbe inutilizzabile nella pratica.\
Passando per la trasformata di fourier, ponendo le attenzioni particolari, possiamo rimanere $O(N log(N))$, ma l'implementazione è meno immediata.

Cominciamo scrivendo:
$
sigma_(A, B) &eq.def "cov"(A, B) \
&= E[(A - mu_A) (B - mu_B)] \
//&= E[(A - mu_A) B - (A - mu_A) mu_B] \
&= E[A B - mu_A B - A mu_B + mu_A mu_B] \
&= E[A B] - E[mu_A B] - E[A mu_B] + E[mu_A mu_B] \
//&= E[A B] - mu_A mu_b - mu_A mu_B + mu_A mu_B \
&= E[A B] - mu_A mu_b \
$

Allora, sappiamo che, a meno di una normalizzazione e fattore di conteggio, possiamo scrivere:
$
"corr"(A, B) = (cal(F)^-1[cal(F)[x]cal(F)^*[x]])/(sigma_A sigma_B)
$
Dove ora non è immediato calcolare le $mu_A, mu_B$ e le $sigma_A, sigma_B$ in quanto richiederebbero tempo lineare nel numero di elementi del dataset per ogni coppia di $A, B$.\

Possiamo ovviare a questo problema utilizzando un _buffer di accumulazione_ $S_i$ (ora utilizzeremo gli indici con base 0):
$
S_(x, i) = sum_(j = 0)^(i-1) x_j
$
Da cui
$
sum_a^b x_i = S_(b) - S_(a)
$
E questo può facilmente generalizzarsi anche nel caso di bidimensionale o più dimensioni.\

#figure(
    image("img/ab_overlap_corr.svg", width: 30%),
    caption: [
        Rappresentazione grafica di $A$ e $B$ al variare di $k$.
    ]
)

Non ho implementato tale metodo in quanto, per ora, non è necessario, ma potrebbe tornare utile in futuro. Riporto un codice C++ di una vecchia implementazione (corrotto, da rivedere e correggere in quanto avevo fatto delle modifiche) che potrebbe tornare utile come reference:
```cpp
void autocorrFFT3(const double* data, double* out_corr, size_t count, double mean, size_t padding)
{
    using namespace pocketfft;

    shape_t shape = { count + padding };
    stride_t strideDouble = { sizeof(double) };
    stride_t strideComplexDouble = { sizeof(std::complex<double>) };

    // if a mean is not zeor or a padding is set, we have to create another array
    std::vector<double> data_vector;
    if (padding != 0)
    {
        data_vector.resize(count + padding);
        for (size_t i = 0; i < count; ++i)
            data_vector[i] = data[i] - mean;
        data = data_vector.data();
    }

    // accumulation buffers
    std::vector<double> accum_x; accum_x.reserve(count + 1);
    std::vector<double> accum_x2; accum_x2.reserve(count + 1);
    {
        double x_sum = 0;
        double x2_sum = 0;
        for (size_t i = 0; i <= count; ++i)
        {
            accum_x.push_back(x_sum);
            accum_x2.push_back(x2_sum);
            x_sum += data[i];
            x2_sum += sqr(data[i]);
        }
    }

    auto mean_data = [&](size_t firstIdx, size_t lastIdx) -> double { return (accum_x[lastIdx] - accum_x[firstIdx]) / (lastIdx - firstIdx); };
    auto var_data = [&](size_t firstIdx, size_t lastIdx) -> double {
        const auto N = lastIdx - firstIdx;
        const auto Ex2 = (accum_x2[lastIdx] - accum_x2[firstIdx]) / N;
        const auto Ex = (accum_x[lastIdx] - accum_x[firstIdx]) / N;
        const auto var = Ex2 - sqr(Ex);
        return var;
    };

    std::vector<double> out_data_vector;
    double* tmp_out_corr = out_corr;
    if (padding != 0)
    {
        out_data_vector.resize(count + padding);
        tmp_out_corr = out_data_vector.data();
    }

    std::vector<std::complex<double>> ft(count + padding);

    // TODO normalization???

    // FT
    pocketfft::r2c<double>(shape, strideDouble, strideComplexDouble, pocketfft::shape_t{ 0 }, pocketfft::FORWARD, data, ft.data(), 1.0);

    // ft <- (ft*)(ft) = |ft|^2
    for (auto& c : ft)
        c = std::conj(c) * c;

    // FT^-1
    pocketfft::c2r<double>(shape, strideComplexDouble, strideDouble, pocketfft::shape_t{ 0 }, pocketfft::BACKWARD, ft.data(), tmp_out_corr, 1.0);

    // counting factor
    //for (size_t k = 0; k < count; ++k)
    //	tmp_out_corr[k] /= (count - k);

    // remove mean
    if (0)
        for (size_t k = 0; k < count; ++k)
            tmp_out_corr[k] -= mean_data(0, count - k) * mean_data(k, count);

    // counting factor
    if (0)
    for (size_t k = 0; k < count; ++k)
        tmp_out_corr[k] /= (count - k);

    // divide var
    if(0)
    for (size_t k = 0; k < count; ++k)
        tmp_out_corr[k] /= sqrt(var_data(0, count - k) * var_data(k, count)) * 0.5;
    tmp_out_corr[count - 1] = 0; // !!!

    // remove mean
    if (0)
    for (size_t k = 0; k < count; ++k)
        tmp_out_corr[k] -= mean_data(0, count - k) * mean_data(k, count);
    tmp_out_corr[count - 1] = 0; // !!!

    // normalization
    //auto tmp_out_corr_0 = tmp_out_corr[0];
    //for (size_t k = 0; k < count; ++k)
    //	tmp_out_corr[k] /= tmp_out_corr_0;

    if (tmp_out_corr != out_corr)
        std::copy(tmp_out_corr, tmp_out_corr + count, out_corr);
}
```

#todo[
    Forse potrebbe essere interessante fare un confronto tra le due definizioni delle autocorrelazioni, ma solo alla fine se mi rimane tempo.
]

= Codebase

Il codice si trova in https://github.com/LucaCiucci/nm4p 

#bibliography("bibliography.yaml")