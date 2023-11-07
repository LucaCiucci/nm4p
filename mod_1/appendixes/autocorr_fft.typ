#import "../../common-typst/defs.typ": *
#let xtasks = yaml("/mod_1/xtask.yaml")

#appendix(label: "autocorrelazione-fft")[Calcolo delle autocorrelazioni tramite FFT][

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

    Il codice Rust per il calcolo delle autocorrelazioni tramite la definizione è straightforward ed è riportato in #code_ref("/common/src/stat.rs", line: "fn autocorr_plain")
    #todo[
        check link and line
    ]

    Per testare l'algoritmo testato l'algoritmo su una distribuzione gaussiana generata tramite @alg-mh-1d.\
    Un esempio di output è riportato in @autocorr_plain.

    #figure(
        stack(
            dir: ltr,
            image("/mod_1/img/plots/autocorr_plain.svg", width: 50%),
            image("/mod_1/img/plots/autocorr_plain-log.svg", width: 50%),
        ),
        caption: [
            Esempio #footnote(raw(xtasks.autocorr_plain, block: false, lang: "sh")) di autocorrelazioni calcolate tramite @ck-plain in scala lineare (a) e logaritmica (b)
        ]
    ) <autocorr_plain>

    Notiamo che in @autocorr_plain, l'andamento per piccoli $k$ è simil-esponenziale, come aspettato. Inoltre $c_0 = 1$ come aspettato.\

    Riducendo il dataset (in quanto l'algoritmo è $O(N^2)$), possiamo vedere l'andamento a grandi $k$ in @autocorr_plain-full.

    #figure(
        image("/mod_1/img/plots/autocorr_plain-full.svg", width: 50%),
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

    Possiamo allora scrivere l'algoritmo per il calcolo delle autocorrelazioni tramite FFT come @ck-fft-1d, il cui codice Rust è riportato in #code_ref("/common/src/stat.rs", line: "fn autocorr_fft")
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
            image("/mod_1/img/plots/autocorr_plain-full.svg", width: 50%),
            image("/mod_1/img/plots/autocorr_fft-full.svg", width: 50%),
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
        image("/mod_1/img/ab_overlap_corr.svg", width: 30%),
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
]