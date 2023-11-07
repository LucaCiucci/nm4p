
#import "../common-typst/defs.typ": *

#set page(paper: "a5")

#show: common_styles

Ho due dubbi:
+ Come trovare l'informazione di fisher per dati correlati
+ quale è la definizione giusta di efficienza di uno stimatore

= $I$ per dati correlati

In generale, sotto le opportune ipotesi, ho:
$
I_mu = E_bold(x) [ -diff^2_mu ln cal(L(bold(x);mu)) ]
$

Se considero $x, y tilde G(mu, sigma)$ e con una correlazione non nulla, posso scrivere:
$
cal(L) prop exp(-1/2 mat(x - mu;y - mu)^T underbrace(mat(sigma_(x x), sigma_(x y); sigma_(y x), sigma_(y y)), Sigma)^(-1) mat(x - mu;y - mu))
$
(che è esattamente quello che succede quando faccio un fit ai minimi quadrati, dove la matrice dei pesi è $W = Sigma^(-1)$) da cui ottengo:
$
ln(cal(L)) &= "cost." - 1/2 mat(delta x,delta y) mat(sigma_(x x), sigma_(x y); sigma_(y x), sigma_(y y))^(-1) mat(delta x;delta y)\
$
$
diff_mu ln(cal(L)) = 1/2(&mat(1, 1) mat(sigma_(x x), sigma_(x y); sigma_(y x), sigma_(y y))^(-1) mat(delta x;delta y) \ + &mat(delta x,delta y) mat(sigma_(x x), sigma_(x y); sigma_(y x), sigma_(y y))^(-1) mat(1;1))
$
$
diff_mu^2 ln(cal(L)) = -mat(1, 1) mat(sigma_(x x), sigma_(x y); sigma_(y x), sigma_(y y))^(-1) mat(1;1)
$
$
I_mu = E[-diff_mu^2 ln(cal(L))] &= mat(1, 1) mat(sigma_(x x), sigma_(x y); sigma_(y x), sigma_(y y))^(-1) mat(1;1)\
&= mat(1, 1) (mat(sigma_x, 0; 0, sigma_y)mat(sigma_x, c sigma_y; c sigma_x, sigma_y))^(-1) mat(1;1)\
&= mat(1, 1) (mat(sigma_x, 0; 0, sigma_y)underbrace(mat(1, c; c, 1), C) mat(sigma_x, 0; 0, sigma_y))^(-1) mat(1;1)\
$
dove $C$ è la matrice di correlazione.

Allora
$
I_mu &= mat(1, 1) mat(1/sigma_x, 0; 0, 1/sigma_y)mat(1, c; c, 1)^(-1) mat(1/sigma_x, 0; 0, 1/sigma_y) mat(1;1)\
&= mat(1/sigma_x, 1/sigma_y)mat(1, c; c, 1)^(-1) mat(1 / sigma_x;1/sigma_y)\
$
Per semplicità metto ora $sigma_x = sigma_y$ perché è il caso che mi interessa per i miei scopi:
$
I_mu = 1/sigma^2 mat(1, 1) mat(1, c; c, 1)^(-1) mat(1;1)\
$ <partial-result-1>

considero:
$
mat(1, c; c, 1)^(-1) mat(1;1) = mat(x;y) <==>
mat(1, c; c, 1) mat(x;y) = mat(1;1)\
<==>
mat(x + c y; c x + y) = mat(1;1)\
<==>
mat((1-c^2)x; c x + y) = mat(1 - c;1)\
#stack($<==>$, $c eq.not 1$)
mat((1+c)x; c x + y) = mat(1;1)\
$
dunque ($c eq.not -1$)
$
mat(x; c 1/(1+c) + y) = mat(1/(1+c);1)\
<==>
mat(x; y) = mat(1/(1+c); 1 - c/(1+c))\
<==>
mat(x; y) = 1/(1+c)
$

Allora @partial-result-1 diventa:
$
I_mu = 2 / (sigma^2 (1 + c)) = underbrace(1/sigma^2, (a)) space underbrace(2 / (1 + c), (b))
$ <fisher-two-correlated-variables>

Che è più che ragionevole ed è valido anche per $c = 1$ (i due dati ci danno la stessa informazioni), mentre nel limite $c -> -1$ significa che ci da informazione infinita su $mu$, che è corretto perché in quel caso $mu = (x + y)\/2$ esattamente.

#question[
    Questo risultato (fattore $(b)$ della @fisher-two-correlated-variables) è generale o vale solo per distribuzioni gaussiane? Non avrei proprio idea di come procedere nel caso di dati non gaussiani, ma spererei che il risultato sia comunque sensato.
]

Nel caso in cui abbia una serie di dati autocorrelati temporalmente ma tutti distribuiti identicamente, posso stimare l'errore sulla media come:
$
sigma_(overline(x))^2 = 1 / N_"eff" sigma_x^2
$
con, l'_effective sample size_, legato al _tempo di correlazione integrato_:
$
N_"eff" = N / (1 + 2 tau_"int") = N / (1 + 2 sum_(k = 1)^infinity c_k) = N / (sum_(k = -infinity)^infinity c_k)
$
e quindi:
$
1/sigma_(overline(x))^2 = underbrace(1/sigma_x^2, (a)) space underbrace(N / (sum_(k = -infinity)^infinity c_k), (b))
$ <fisher-N-correlated-variables>

Allora mi pare ovvio che posso identificare i pezzi $(a)$ e $(b)$ di @fisher-two-correlated-variables e @fisher-N-correlated-variables per ottenere:
$
I_mu = I_x N / (sum_(k = -infinity)^infinity c_k) = I_x N_"eff"
$ <fisher-N-correlated-variables-2>

Che sembra un risultato *super ragionevole* (qui $I_x$ è l'informazione di una singola misura).

#question[
    Questo risultato è corretto/giustificabile? E' a conoscenza di qualche reference a cui fare riferimento per la giustificazione nell'utilizzo di questa relazione?\
    Come prima, vale anche per il caso non gaussiano? (questa è la domanda che mi interessa di più)
]

#note[
    Vorrei utilizzare questo ultimo risultato per trovare un parametro per cui ho un efficienza massima per un certo estimatore e vorrei utilizzare la relazione @fisher-N-correlated-variables-2 per trovarne il bias evitando di calcolarlo esplicitamente con i valori di aspettazione visto che potrebbe essere laborioso.

    Per essere chiari, lo stimatore che vorrei studiare è questo (@efficient-autocorrelation-spectra):
    $
    hat(tau)'^((2M))_("int", A) := (4M dot hat("Var")A^(2M) - M dot hat("Var")A^(M)) / (hat("Var")A^(1))
    $
    su cui voglio ottimizzare $M$. Che si comporta come questo grafico blu:
    #figure(image("img/plots/binning-comparison.svg", width: 75%))
]

= Efficienza di uno stimatore

A lezione si è detto che per uno stimatore con bias:
$
epsilon_S (mu) = (1 + diff_mu b)^2 I_S^(-1) "var"[S]^(-1)
$ <def-efficienza-stimatore-lesson>

Quello che mi sembra strano è che compaia $I_S$ e non $I_mu$, infatti mi aspetterei che il parametro di efficienza quantifichi quanto funziona bene lo stimatore e quindi quanto bene stia utilizzando i dati in input.

So che il parametro di efficienza è solo una definizione e quindi posso definirlo come mi pare, ma mi sembra ragionevole che quantifichi qualcosa di sensato. Cioè che possa utilizzare questo parametro per fare decisioni su quale stimatore utilizzare.

Mi aspetto infatti che la definizione @def-efficienza-stimatore-lesson possa portare a cose strane tipo $epsilon_S (mu) = 1$ nel caso di uno stimatore senza bias distribuito gaussianamente.

Se prendo ad esempio uno stimatore $S^((m))$, vorrei utilizzare $epsilon_S (mu)$ per decidere quale valore di $m$ utilizzare per avere la miglior efficienza possibile, ovvero per estrarre il *massimo di informazione* che posso *#underline[dai dati]*.

Vorrei quindi utilizzare la definizione:
$
epsilon_S (mu) = (1 + diff_mu b)^2 I_mu^(-1) "var"[S]^(-1)
$ <def-efficienza-stimatore-my>
invece di @def-efficienza-stimatore-lesson.

Considero ad esempio dei dati distribuiti gaussianamente:
$
{x_i} = X = "iid" tilde G(mu, sigma^2)
$
e lo stimatore:
$
S^((m))[X] = 1/m sum_(i = 1)^m x_i
$ <def-stimatore-media>

Mi pare intuitivo che
$
epsilon_(S^((m))) = m / N
$ <efficienza-stimatore-aspettato>
ma @def-efficienza-stimatore-lesson mi da *sempre 1*.

Infatti sappiamo che la distribuzione di @def-stimatore-media è:
$
S^((m))[X] = 1/m sum_(i = 1)^m x_i tilde G(mu, sigma^2 / m)
$

allora ($sigma_S^2 = sigma^2\/m$):
$
cal(L)(S) prop exp(-1/2 (S - mu)^2 / sigma_S^2)
$
$
ln(cal(L)) = "cost." -1/2 (S - mu)^2 / sigma_S^2
$
$
diff_mu ln(cal(L)) = (S - mu) / sigma_S^2
$
$
diff_mu^2 ln(cal(L)) = -1 / sigma_S^2
$
e quindi, l'informazione che il mio estimatore mi da su $mu$ è:
$
I^((s^((m))))_mu = 1 / sigma_S^2
$
che è ovvio. Ma allora, usando @def-efficienza-stimatore-lesson:
$
epsilon_(S^((m))) = 1
$
che non dipende da $m$!.

Ovviamente si potrebbe argomentare che lo stimatore $S^((m))$ *non è consistente*, ma il punto era solo costruire un estimatore con distribuzione finale gaussiana, avrei potuto ugualmente prendere uno stimatore consistente tipo:
$
S^((m))[X] = 1 / floor(N / m) sum_i^(floor(N / m)) x_(i m)
$
e sarebbe venuta la stessa cosa, ma nei conti sopra era comodo non portarmi dietro robe inutili tipo $floor(N / m)$. Il risultato sarebbe stato lo stesso.

Invece se avessi usato @def-efficienza-stimatore-my, sarebbe venuto:
$
epsilon_(S^((m))) = I_mu^(-1) sigma_S^2 ^(-1) = sigma^2 / N space m / sigma^2 = m / N
$
che coincide con quello che mi aspettavo (@efficienza-stimatore-aspettato).

#question[
    La definizione @def-efficienza-stimatore-my ha senso? Posso utilizzarla per decidere quale stimatore utilizzare invece di @def-efficienza-stimatore-lesson?
]

Non ho ancora fatto miei i concetti trattati nel corso, quindi non escludo che li sto applicando male o che mi sto perdendo qualcosa di importante o mi sto complicando troppo la vita.

#bibliography("bibliography.yaml")