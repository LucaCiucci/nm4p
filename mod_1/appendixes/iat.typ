#import "../../common-typst/defs.typ": *

#let xtasks = yaml("/mod_1/xtask.yaml")

#appendix(label: "IAT")[Integrated Autocorrelation Time][

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

    We can also define the _effective sample size_:
    $
    "ESS" = N_"eff" = N / (1 + 2 tau_"int")
    $
    so that @var-of-mean-corrected becomes:
    $
    sigma_overline(x)^2 = 1/N sigma_x^2 (1 + 2 tau_"int") = sigma_x^2 / N_"eff"
    $
    #todo[
        fai vedere come questo e quello sotto è in relazione con info di fisher, vedi PDF
    ]
    and we also define the ratio between $N$ and $N_"eff"$:
    $
        R = N / N_"eff" = 1 + 2 tau_"int"
    $

    == $tau_"int"$ with explicit summation

    Per analizzare il comportamento di $tau_"int"$, definiamo:
    $
    tau_"int" (M) = sum_(k = 1)^M (1 - k/N) c_k
    $

    #figure(
        image("/mod_1/img/plots/autocorr-int.svg", width: 50%),
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
            image("/mod_1/img/plots/autocorr-int-full.svg", width: 50%),
            image("/mod_1/img/plots/autocorr-int-full-corrected.svg", width: 50%),
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
            stack(image("/mod_1/img/plots/autocorr-int-algo.svg", width: 50%), [(a)]),
            stack(image("/mod_1/img/plots/autocorr-int-algo-int.svg", width: 50%), [(b)]),
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
            stack(image("/mod_1/img/plots/autocorr-int-algo-deriv.svg", width: 50%), [(a)]),
            stack(image("/mod_1/img/plots/autocorr-int-algo-deriv-int.svg", width: 50%), [(b)]),
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
        image("/mod_1/img/plots/autocorr-int-finder-tau_int-vs-iter.svg", width: 50%),
        caption: [
            Andamento dei tempi di autocorrelazione integrati in funzione di $N$ per entrambi gli algoritmi #footnote(raw(xtasks.autocorr-int-finder-tau_int-vs-iter, block: false, lang: "sh")). In nero è riportato il risultato e la varianza con $M$ calcolato con@alg-estimate-M mentre in rosso @alg-estimate-M-deriv.
        ]
    ) <autocorr-int-finder-tau_int-vs-iter>

    Da @autocorr-int-finder-tau_int-vs-iter osserviamo che entrambi gli algoritmi sembrano tendere ad uno stesso valore, che è quello che ci aspettiamo. Inoltre, @alg-estimate-M-deriv, pur avendo una varianza minore, converge più lentamente, sia per $N$ intermedi che per $N$ grandi, per questo motivo in tutte le analisi successive sarei tentato di usare @alg-estimate-M per cui è richiesto un $N$ minore prima di essere "ragionevolmente"!!!!! alla convergenza.

    #warning[
        I did not made any further analysis of these estimators' biases since this is not the main focus of this work and, for our purposes, we only need a rough estimate of $tau_"int"$ that we will refine with binning (see @binning).
    ]

    C'è però un altro metodo semplice e più corretto per stimare $M$: la somma di due $c_k$ consecutivi è sempre positiva (vedi @betanalpha-mcmc-in-practice), per cui, possiamo stimare $M$ come il primo $m$ tale che $c_m + c_(m + 1) < 0$.
    #algorithm(
        title: [Stima di $M$ tramite derivata somma di due $c_k$ successive],
        label: "alg-estimate-M-sum",
    )[
        + Calcola le ${c_k}$
        + trova il primo $m$ tale che $c_m + c_(m + 1) < 0$
        + $M = m$
    ]
    Questo metodo sembra essere più rigoroso e meno sensibile al rumore rispetto a @alg-estimate-M. Nella pratica, per la distribuzione considerata, i risultati sono comparabili a @alg-estimate-M. Ho quindi deciso di utilizzare @alg-estimate-M-sum per stimare $M$.

    #note[
        @alg-estimate-M-sum è meglio di @alg-estimate-M perché quando c'è una correlazione molto negativa, @alg-estimate-M non funziona perché lo zero viene subito raggiunto, mentre @alg-estimate-M-sum funziona perché la somma di due $c_k$ consecutive è sempre positiva.
        ```bob-50
        ^"c_k"               ^ c_k + c_(k + 1)
       1|─╮                  |─╮
        | │╭╮                | ╰─╮
        | │||╭╮              |   ╰─╮
        | │||||╭╮     ∑      |     ╰─
      --+-+++++++->   ->   --+--------->
        | │|||╰╯             |
        | │|╰╯               |
        | ╰╯                 |
        ```
    ]

    Notiamo inoltre, dai grafici precedenti @autocorr-int-algo-out e @autocorr-int-algo-out-deriv, che gli algoritmi fanno pressappoco ciò che faremmo "ad occhio", quindi userò @alg-estimate-tau-int associato ad @alg-estimate-M per stimare $tau_"int"$ anziché farlo manualmente onde evitare errori umani.
    Per quanto riguarda la non correttezza della stima per $N$ non sufficientemente grandi, notiamo che si avrebbe lo stesso problema con una selezione manuale di $M$: manualmente prenderemmo un $M$ tale che il grafico di $tau_"int"(M)$ si "appiattisca", ma questo è esattamente quello che sta facendo l'algoritmo e dunque la problematica è esattamente la stessa.

    Da @autocorr-int-finder-tau_int-vs-iter possiamo inoltre dire che l'algoritmo fornisce stime ragionevolmente valide per $N gt.approx 1000 tau_"int"$, come nel caso del metodo di Sokal @mcm-stat-mech-sokal, anche se per i nostri scopi anche valori $N gt.approx 100 tau_"int"$ (o probabilmente anche meno) sarebbero sufficienti. Per non perderci in dettagli implementativi, ho fatto in modo che l'algoritmo semplicemente non restituisca nulla in output (rappresentando un errore di utilizzo) se $N < 100 tau_"int"$.\
    Inoltre a differenza del metodo di Sokal, non è richiesta alcuna costante arbitraria $C$.

    Ho dunque deciso di proseguire utilizzando tale algoritmo per la stima di $tau_"int"$, il cui corrispondente codice si trova in #code_ref("/common/src/stat.rs", line: "pub fn estimate_rough_tau_int(x: &[f64]) -> Option<f64>").
    #todo[
        check link and line
    ]

    Con gli strumenti appena descritti, possiamo stimare il tempo di autocorrelazione integrato per l'algoritmo di metropolis applicato alla distribuzione gaussiana vs accettazione. Un esempio di tale stima è riportato in @metrogauss-tau_vs_acc.
    #figure(
        image("/mod_1/img/plots/metrogauss-tau_vs_acc.svg", width: 50%),
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

    Come visto in @IAT, per stimare la varianza associata alla madia campionaria in un set di dati correlati temporalmente, è possibile necessario stimare il tempo di autocorrelazione integrato $tau_"int"$ tramite @var-of-mean-corrected, che è quello che abbiamo fatto nella sezione precedente.\
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
    1 + 2 tau_"int" = lim_(k -> infinity) ("var"(overline(x_i^k)) / "var"(overline(x_i)))
    $ <binning-tau-int>
    dove $"var"(x_i)$ è l'estimatore:
    $
    "var"(x_i) = 1 / (N - 1) sum_(j = 1)^(N) (x_j - overline(x))^2
    $ <def-var-estimator>
    #todo[
        @def-var-estimator va scritta prima e fai una reference al codice
    ]
    Cioè, inserendolo nella @var-of-mean-corrected, possiamo semplicemente stimare:
    $
    sigma_overline(x)^2 = lim_(k -> infinity) "var"(x_i^k) / k
    $
    Che è quello che ci interessava.

    In practice, we cannot compute this limit. If $N$ is the number of samples, the number of blocks will be $floor(N\/k)$ and this means that we can expect the associated statistical error to scale (for large $N$) as $tilde sqrt(k)$.\
    This means we cannot simply choose $k$ to be very large, as this would make the error too large having a very small number of blocks.\

    We can also see that each block has a correlation with the following one that (for large $N$ and $k$) scales as $tilde 1 \/ k$. This means $k$ should not be large, otherwise the bias will be important.
    #todo[
        controlla $tilde 1 \/ k$
    ]
    #todo[
        ref to bias equation
    ]

    To further investigate the scaling of the error, we generate a dataset with a known exponential autocorrelation:
    $
    x_(i + 1) &= e^(-1\/tau) x_i + y_i sqrt(1 - e^(-2\/tau)) \
    &eq.def a x_i + b y_i
    $ <test-dataset-exp-correlation>
    with:
    $
    { y_i } = "iid" tilde N(mu = 0, sigma = 1); x_0 tilde N(mu = 0, sigma = 1)
    $
    Da cui possiamo verificare che:
    $
    sigma_(x_i)^2 = 1\
    $
    e
    $
    "cov"(x_i, x_(i + k)) &= "cov"(x_i, a^k x_i + sum_(j = 0)^(k - 1) a^j b y_(i + j)) \
    &= "cov"(x_i, a^k x_i) \
    &= a^k "cov"(x_i, x_i) \
    &= e^(-k\/tau)
    $
    Quindi ci aspettiamo semplicemente:
    $
    c_k = e^(-k\/tau)
    $
    che, dalla @tau_int_of_tau_exp abbiamo:
    $
    tau_"int" &= e^(-k \/ tau) / (1 - e^(-k \/ tau))
    $

    //#image("img/plots/binning.svg")
    #figure(
        image("/mod_1/img/plots/binning.svg", width: 50%),
        caption: [
            Tipical trend of $tau_"int"$ computed using @binning-tau-int for a dataset with exponential autocorrelation @test-dataset-exp-correlation.
            The variance is estimated by repeating the binning process multiple times and computing the variance of the results. #footnote(raw(xtasks.binning, block: false, lang: "sh")).
        ]
    ) <binning-trend>

    As we can see from @binning-trend, this $tau_"int"$ estimator converges slowly to the true value. In particular, for large $k$ there is a bias that improves like $tilde 1 \/ k$ but the variance increases like $tilde sqrt(k)$ (see @efficient-autocorrelation-spectra). This makes the choice of a trade-off between bias and variance difficult.\

    To solve this problem, @efficient-autocorrelation-spectra suggests to estimate the correction factor. The bias correction for $tau_"int"$ for our definition results in:
    $
    tau'_"int" (2 k) eq.def 2 tau_"int" (2 k) - tau_"int" (k)
    $ <binning-tau-int-corrected>

    #figure(
        image("/mod_1/img/plots/binning-comparison.svg", width: 50%),
        caption: [
            Comparison between @binning-tau-int (black) and @binning-tau-int-corrected (blue). We can see that the bias-corrected estimate converges nearly as fast as the explicit autocorrelation factor summation (red). The green line and band is the estimate and variance of the rough estimate @alg-estimate-tau-int. #footnote(raw(xtasks.binning-comparison, block: false, lang: "sh")).
        ]
    ) <binning-trend-comparison>

    As observed in @efficient-autocorrelation-spectra, the bias-corrected estimator @binning-tau-int-corrected converges nearly as fast as the explicit autocorrelation factor summation.\
    Following this conclusion, we might be tempted say that the explicit autocorrelation factor summation the best estimator for $tau_"int"$, but this is not a general result. In particular, MC methods might show strong negative autocorrelations (see @betanalpha-mcmc-in-practice) and this might presents a vulnerability for @alg-estimate-M-sum since fluctuations of the autocorrelation estimates might lead to highly underestimated cutoffs.

    I then decided to analyze the efficiency of the bias corrected estimator ()said $theta$.
    $
    theta = ??????? prop
    $
    #todo[
        continua
    ]

    I thus decided to use the following approach:
    + use @alg-estimate-tau-int in combination with @alg-estimate-M-sum to estimate $tau_"int"$
    + use this estimate to pick $k tilde 10 tau_"int"$
    + use @binning-tau-int-corrected obtain a new to estimate for $tau_"int"$
    + use the new estimate to pick $k tilde 10 tau_"int"$
    + @binning-tau-int-corrected again to obtain the final estimate for ESS using @def-ESS
    Note that we do not iterate until convergence since there is no guarantee that the estimate will converge, it is likely that we would enter a loop of oscillations.

    #todo[
        move
    ]
    $
    "ESS" eq.def N / (1 + 2 tau_"int")
    $ <def-ESS>
    $
    "correct var" (= "var"(overline(x_i^k)) / k) = "var"(overline(x_i)) / (1 + 2 tau_"int") = "ESS" / N "var"(overline(x_i))
    $
    $
    ==> "ESS"/N = "correct var" / "var"(overline(x_i))
    $

    #let r = yaml("/mod_1/img/plots/test-tau-int-estimate.yaml")
    #format_with_err(r.estimated, r.uncertainty)

    #let c = {
        import "@preview/cetz:0.1.2": canvas, draw, tree
        let c = canvas(length: 1cm, {
            import draw: *

            set-style(content: (padding: .2))

            let data = (
                $x^((8))_0$,
                ($x^((4))_0$, ($x^((2))_0$, $x^((1))_0$, $x^((1))_1$), ($x^((2))_1$, $x^((1))_2$, $x^((1))_3$)),
                ($x^((4))_1$, ($x^((2))_2$, $x^((1))_4$, $x^((1))_5$), ($x^((2))_3$, $x^((1))_6$, $x^((1))_7$)),
            );

            let y = -3.5;
            let x = -0.5;
            line((-0.5, y), (8, y), mark: (end: ">"))
            line((x, y), (x, 1), mark: (end: ">"))
            content((8, y + 0.25), [index])
            content((x + 0.25, 0.75), $k$)
            tree.tree(
                data,
                spread: 1.0,
                grow: 1.0,
                stroke: gray + 2pt,
                name: "tree",
                draw-edge: (from, to, ..) => {
                    let (a, b) = (from + ".center",
                    to + ".center")
                    line((a: a, b: b, abs: true, number: .35),
                    (a: b, b: a, abs: true, number: .35), mark: (start: ">"))
                }
            );
        });
        c
    }

    #figure(
        c,
        caption: [
            Logarithmic binning: bins are averaged 2-by-2 while doubling the $k$ from bottom to top, i.e. $x^((2k))_i = (x^((k))_(2i) + x^((k))_(2i + 1))\/2$
        ]
    )
]