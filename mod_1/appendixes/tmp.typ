#set page(paper: "a5")

Monte carlo for quantum mechanics
$
lr(angle.l O angle.r) = "Tr"(e^(-beta H) angle.l O angle.r) / "Tr"(e^(-beta H))
$
if we take $O = e^((beta - alpha) H)$:
$
lr(angle.l O_alpha angle.r) = "Tr"(e^(-beta H) e^((beta - alpha) H)) / "Tr"(e^(-beta H)) = "Tr"(e^(-alpha H)) / "Tr"(e^(-beta H)) = Z(alpha) / Z(beta)
$
but $Z(beta) in RR$ e $Z(beta) > 0$:
$
lr(angle.l O_alpha angle.r) prop Z(alpha)
$
In particular:
$
lr(angle.l O_alpha angle.r) = 0 <==> Z(alpha) = 0
$

$
Z'(alpha) &= diff_alpha "Tr"(e^(-alpha H))\
&= diff_alpha sum_n e^(-alpha E_n)\
&= -sum_n E_n e^(-alpha E_n)\
&= -"Tr"(H e^(-alpha H))\
$
Similarly:
$
Z^((n)) &= diff_alpha^((n)) "Tr"(e^(-alpha H))\
&= (-1)^n sum_n E_n^n e^(-alpha E_n)\
&= (-1)^n "Tr"(H^n e^(-alpha H))\
$

Similarly, if we take $O = e^((beta - i a) H)$:
$
angle.l O_a angle.r prop Z(i a)
$
and:
$
diff_a Z(i a) &= -sum_n E_n e^(-i a E_n)\
&= -"Tr"(H e^(-i a H))\
$
And, here, we could take $cal(F)^(-1)$ and use $E_n in RR$ to estimate the spectrum, scaling the eigenvalues by a factor so that $E_0$ matches the ground state energy estimated with other methods (because we don't know the pre-factor $1\/Z(beta)$).

Prof says this won't work $-->$ ... but I think maybe $x(tau) -> tilde(x)(tau)$ using Fourier could solve the divergence problem... Also maybe evaluate $Z(beta + i a)$ might be much easier than $Z(i a)$, but using $cal(F)^(-1)$ would be a little more tricky (maybe a mix of Fourier and Laplace transform, nothing too exoteric but complex in practice).