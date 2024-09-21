= Modulo 1

== Introduzione

In questo progetto mi sono occupato dell'applicazione dell'algoritmo di Metropolis al caso unidimensionale ed al modello di Ising 2D.

== Algoritmo di Metropolis-Hastings <the-metropolis-hastings-algorithm>

L'algoritmo di metropolis è permette di campionare distribuzioni di probabilità tramite una catena di Markov. E' un approccio indiretto per le simulazioni di distribuzioni complesse che permetter di superare il problema del "course of dimensionality" incontrato nelle simulazioni dirette.

=== Applicazione ad una distribuzione gaussiana

#figure(
  image("figs/metrogauss/offset.png", width: 75%),
  caption: [
    Visualizzazione dell'output dell'algoritmo di Metropolis-Hastings applicato ad una distribuzione gaussiana.
  ]
) <primo_test_metrogauss>

Come si vede in @primo_test_metrogauss[?] l'algoritmo produce una sequenza di valori che, dopo un certo numero di iterazioni, si stabilizza ed oscilla attorno al valore atteso $mu = 10$. In seguito si analizzerà in dettaglio l'output dell'algoritmo, ma notiamo già che la sequenza di valori prodotta dall'algoritmo è correlata

#figure(
  stack(
    stack(
      stack(image("figs/metrogauss/high-acc.png", width: 50%), [(a)]),
      stack(image("figs/metrogauss/low-acc.png", width: 50%), [(b)]),
      dir: ltr
    ),
    stack(image("figs/metrogauss/med-acc.png", width: 50%), [(c)]),
  ),
  caption: [
    Different acceptance rates for the Metropolis algorithm with a gaussian target distribution and uniform proposal, obtained by varying $delta$. Small $delta$ leads to high acceptance rate (a) and large $delta$ leads to low acceptance rate (b), both leading to high autocorrelation times. A medium $delta$ (c) leads to an acceptance rate of about 50% and a low autocorrelation time.
  ]
)

