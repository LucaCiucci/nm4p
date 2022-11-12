
# Ciao

## Metropolis alg. application

We want to compute the expectation value of an observable $O$. From thermodynamics, we have (in matrix form):
$$
	\braket{O}_T = \frac{\text{Tr}\left(e^{-\beta H} O\right)}{\text{Tr}\left(e^{-\beta H}\right)}
$$
Where $\beta := 1/T$, thus, in a particular base, we have:
$$
\braket{O}_T = \frac{\sum_n \braket{n | e^{\beta H} O | n}}{\sum_n \braket{n | e^{\beta H} | n}} =: \sum_n P_n O_n
$$
Where $\{\ket{n}\}$ is a complete set of the hilbert space, it is not required to be the eigenvalue base ($H\ket{n} = E_n\ket{n}$) since the trace of a matrix is the same independent of the base. We thus denote as $\{\ket{\alpha}\}$ the computational base:
$$
\braket{O}_T = \frac{\sum_\alpha \braket{\alpha | e^{\beta H} O | \alpha}}{\sum_\alpha \braket{\alpha | e^{\beta H} | \alpha}} =: \sum_n P_n O_n
$$


---
---
---
---

...
<!-- TODO ... -->
<span style="color: red"> TODO ... </span>

---
---
---
---

So, all in all, we have:
$$
\begin{split}
	\braket{O}_T &= \frac{\text{Tr}\left(e^{-\beta H} O\right)}{\text{Tr}\left(e^{-\beta H}\right)} \\
	&= \frac{\mathcal{N} \int \mathcal{D}x \, e^{-\frac{S_E[x]}{\hbar}} \, O[x]}{\mathcal{N} \int \mathcal{D}x \, e^{-\frac{S_E[x]}{\hbar}}} = ... \\
	&= \int \mathcal{D}x \, P[x] \, O[x]
\end{split}
$$
Where
$$
	P[x] = \frac{e^{-\frac{S_E[x]}{\hbar}}}{\int \mathcal{D}x \, e^{-\frac{S_E[x]}{\hbar}}} 
$$
and
$$
	S_E[x] = \int_{0}^{\beta \hbar} d\tau' \, \left(\frac{p^2(x)}{2m} + V(x)\right)
$$

Note that, the replacement of $O(x(0)) \rightarrow O[x]$ is legit since the above equations are invariant for euclidean time translations ($\tau \rightarrow \tau + \xi$). This is helpful from a numerical point of view: instead of computing the average of the observable over the first point at each monte carlo time, we can perform an average over all the points in the euclidean time, this means we will have $N$ times measures.

Moving to the lattice:
$$
\begin{split}
	S_L[x] \;(\approx \frac{S_E[x]}{\hbar}) :&= \frac{1}{\hbar} \sum_{j = 0}^{N - 1} a \left[ L_E\left(x(\tau_j); \dot{x}(\tau_j)\right) \right] \\
	&= \frac{1}{\hbar} \sum_j a \left[ L_E\left(x_j; \dot{x}(\tau_j)\right) \right] \\
	&\approx \frac{1}{\hbar} \sum_j a \left[ L_E\left(x_j; \frac{(x_{j + 1} - k_j)}{a}\right) \right] \\
	&=: S_L[\{x_j\}]
\end{split}
$$
Where we defined the points $x_j = a j$, $x_{j + N} = x_j$ and $a = \frac{\beta \hbar}{N}$.

Now, while we could simply continue constructing the metropolis algorithm and let the problem define the corresponding euclidean lattice action $S_L$, but, to simplify this process and to work with adimensional coordinates, we want to work this definition a little bit.

### `AbstractMultiParticleAction`

We introduce the utility class `AbstractMultiParticleAction` that is used to simplify the action definition in the simple case where:
$$
L_E = \left(\sum_i \frac{1}{2} m^i \left(\frac{dx^i}{d\tau}\right)^2\right) + V(\{x^i\})
$$
because this is simply applicable to the case of interacting particles.
Now, on the lattice, we can write:
$$
\begin{split}
	S_L[\{x_j\}] &= \frac{1}{\hbar} \sum_j a\left[\left(\sum_i \frac{1}{2} m^i \left(\frac{x^i_{j + 1} - x^i_j}{a}\right)^2 \right) + V\left[\{x^i_j\}\right]\right] \\
	&= \frac{1}{\hbar} \sum_j \frac{\beta\hbar}{N}\left[\left(\sum_i \frac{1}{2} m^i \left(\frac{x^i_{j + 1} - x^i_j}{a}\right) ^2\right) + V\left[\{x^i_j\}\right]\right] \\
	&= \frac{\beta}{N} \sum_j \left[\left(\sum_i \frac{1}{2} m^i \left(\frac{x^i_{j + 1} - x^i_j}{a}\right)^2 \right) + V\left[\{x^i_j\}\right]\right] \\
	%&= \sum_j \frac{1}{N}\left[\left(\sum_i \frac{\beta}{2m^i} \frac{(x^i_{j + 1} - x^i_j)^2}{a^2} \right) + \beta V\left[\{x^i_j\}\right]\right] \\
	%&= \sum_j \frac{1}{N}\left[\left(\sum_i \frac{\beta N^2}{2m^i} \frac{(x^i_{j + 1} - x^i_j)^2}{\beta^2\hbar^2} \right) + \beta V\left[\{x^i_j\}\right]\right] \\
	%&= \sum_j \frac{1}{N}\left[\left(\sum_i \frac{\beta N^2}{2m^i} \frac{(x^i_{j + 1} - x^i_j)^2}{\beta^2\hbar^2} \right) + \beta V\left[\{x^i_j\}\right]\right]
\end{split}
$$

Now, in a generic problem, we could try to find a variable change in order to use adimensional variables through the virial theorem. Since the generic [trattazione] of this problem might be formally difficult due to the mutlidimensionality of the problem, we will set aside this [questione] and proceed by generalizing the action:
$$
\begin{split}
	S_L[\{x_j\}] &= \frac{\beta}{N} \sum_j \left[\left(\sum_i \frac{1}{2} m^i \left(\frac{x^i_{j + 1} - x^i_j}{a}\right)^2 \right) + V\left[\{x^i_j\}\right]\right] \\
	&=: \sum_j \left[ \left(\sum_i k^i (x^i_{j + 1} - x^i_j)^2 \right) + \tilde{V}\left[\{x^i_j\}\right] \right]
\end{split}
$$
We then the subclasses will take charge of defining the virtual functions `kin` and `veff`:
$$
\verb!kin(i)! := \frac{\beta}{2Na^2} m^i = \frac{N}{2\beta\hbar^2} m^i
$$
$$
\verb!veff(xx)! := \tilde{V}\left[\{x^i_j\}\right] = \frac{\beta}{N} V\left[\{x^i_j\}\right]
$$

> NOTA!!!!!!!: è vero che sul $\tilde{V}$ compare $1/N$, però poi c'è somma su j che porta $\sim N$, Però c'è anche sul termine cinetico.........

#### `GuessProvider` for the `AbstractMultiParticleAction`

In the limit of small lattice step ($\lim_{N \rightarrow \infty}$), we expect that the kinetic term is dominant (MI SA CHE INTENDO SOLO NELLA PARTE QUADRATICA (DERIVATA SECONDA)) since it depends on $1/a$ (see the 1d-HO example below in the limit of small $\eta$):
$$
S_L[\{x_j\}] \simeq \sum_j \left(\sum_i k^i (x^i_{j + 1} - x^i_j)^2 \right)
$$
We can then recognize that, in the coordinate variation for a specific $\tau$ given by $j$, the associated distribution probability ??? <!-- TODO define P[x] --> is a gaussian, centered in $x^i_{j + 1}$ and with variance $(k^i)^{-1}$ (i.e. $\sigma^i = \sqrt{(k^i)^{-1}}$):
$$
P[x^i_{j + 1}] = \frac{1}{\sqrt{2\pi}\;\sigma^i} \exp\left(-\frac{(x^i_{j + 1} - x^i_j)^2}{2(\sigma^i)^2}\right)
$$
In order to sample this distribution, we can then recall the metropolis gauss algorithm, where we use $\delta^i$ in the order of magnitude of $\sigma^i$: we choose:
$$
\delta^i = \alpha \sigma^i
$$
The parameter alpha is arbitrary, but the optimale value for a gaussian distribution is $\alpha = ???$.

We can thern define a guess provider that can be requested for the specific multi-particle problem (see `AbstractMultiParticleAction::guessProvider`).

#### Example: 1d-HO

For the 1d-HO we have:
$$
S_L = \frac{1}{\hbar} \sum_j a \left[ \frac{1}{2} m \frac{(x_{j + 1} - x_j)^2}{a^2} + \frac{1}{2} m \omega^2 x_j^2 \right]
$$
We can then use adimensional units by performing the variable change (for the isotropic HO $\ell = \sqrt{\frac{\hbar}{m\omega}}$):
$$
x_j = \sqrt{\frac{\hbar}{m\omega}} \;\; y_j
$$
in this units:
$$
\begin{split}
	S_L &= \frac{1}{\hbar} \sum_j a \left[ \frac{1}{2} m \frac{\hbar}{m\omega} \frac{(y_{j + 1} - y_j)^2}{a^2} + \frac{1}{2} m \frac{\hbar}{m\omega} \omega^2 y_j^2 \right] \\
	&= \sum_j \left[\frac{1}{2\eta} (y_{j + 1} - y_j)^2 + \frac{1}{2}\eta y_j^2\right]
\end{split}
$$
where
$$
\eta = \omega a
$$
This means:
$$
\verb!kin(i)! := \frac{1}{2\eta}; \;\; \verb!veff(yy)! := \frac{1}{2}\eta \sum_{y \in yy} y^2
$$
Now, the dependency on $\beta$ is hidden in the definition of $\eta$ and this reflects the equivalence of all the 1d-HOs.

In the code, this system is implemented in the `HO_1P_Action` class, where $\eta$ is the only controllable parameter of the problem.

> **Note:**
> In a generic problem, $\beta$ is usually a parameter of the problem.

### Completing the Metropolis alg. implementation

At this point, the implementation of the algorithm is trivial:
```cpp
void metropolis(...) {
	for (iteration) {
		for (i0) {
			guess = ...
			SL_variation = actionFunctional.evalDiff(trajectory, i0, guess);
			r = exp(-SL_variation);
			if (trueWithProbability(r))
				accept();
			measure();
		}
	}
}
```



Now, we want to remove the explicit dependency on $\hbar$ in the sum and 