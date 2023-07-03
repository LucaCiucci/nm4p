/*!
From [`congruent_random_number_generator.f`](../fortran_src/congruent_random_number_generator.f) (M. D'Elia - 09/2018)

NOTE: integer(16) in Fortran is i128 in Rust
we require quite large integers for the generator.
From numerical recipes p.299 https://web.archive.org/web/20230119132211if_/https://websites.pmc.ucsc.edu/~fnimmo/eart290c_17/NumericalRecipesinF77.pdf#page=299 you can see an implementation
that uses only small integers

NOTE: we do not implement RngCore because this would be non trivial as the generator
does not provides numbers in 0..2^128-1 but in 0..m-1. It would be difficult to efficiently generate
uniformly distributed numbers in an full integer range (u32 and u62 are required for RngCore).
*/

pub const DEFAULT_SEED: i128 = 2;

/// A congruent random number generator step
///
/// This function takes the current state `x_k` and the parameters of the generator,
/// returns the next state `x_{k+1} = (x_k * a + c) mod m`.
///
/// This function is used by [`Generator`] to generate random numbers.
///
/// # Arguments
/// * `x_k` - the current state
/// * `p` - the parameters of the generator
///
/// # Returns
/// The next state `x_{k+1}`
///
/// # Example
/// ```
/// use codici_mod_0::congruent_random_number_generator::*;
///
/// let x_k = 2;
/// let params = Parameters::default();
/// let x_k_plus_1 = congruent_random_number_generator_step(x_k, &params);
///
/// assert_eq!(x_k_plus_1, 96542);
/// ```
#[must_use]
pub fn congruent_random_number_generator_step(
    x_k: i128,
    p: &Parameters,
) -> i128 {
    // linear transformation + mod
    (x_k * p.a + p.c).rem_euclid(p.m)
}

/// The Congruent Random Number Generator
///
/// This generator is based on the congruent random number generator described in
/// [`congruent_random_number_generator_step`]
///
/// You can find an example usage in the `examples` folder.
///
/// Note: To build a generator, you can use any of the following:
/// - [`Generator::new`]
/// - [`Generator::default_with_seed`]
/// - [`Generator::default`]
///
/// # Example
/// ```
/// use codici_mod_0::congruent_random_number_generator::*;
///
/// let mut rng = CongruentGenerator::default();
/// for _ in 0..10 {
///     println!("{}", rng.generate());
/// }
/// ```
pub struct CongruentGenerator {
    /// current state
    ///
    /// This is the `x_k` in [`congruent_random_number_generator_step`]
    x: i128,

    /// parameters of the generator
    params: Parameters,
}

// TODO copilot randomly mentioned https://doi.org/10.1016/j.cpc.2019.106949
// while I was writing this doc for Generator, check it out

impl Default for CongruentGenerator {
    fn default() -> Self {
        Self::default_with_seed(DEFAULT_SEED)
    }
}

impl CongruentGenerator {
    /// Create a new generator with a given seed and parameters
    pub fn new(seed: i128, params: Parameters) -> Self {
        Self {
            x: seed,
            params,
        }
    }

    /// Create a new generator with a given seed and default parameters
    ///
    /// Check [`Parameters`]'s [`Default`] implementation for the default parameters
    pub fn default_with_seed(seed: i128) -> Self {
        Self::new(seed, Parameters::default())
    }

    /// Generate a random number in `[0,1)`
    pub fn generate(&mut self) -> f64 {
        self.x = congruent_random_number_generator_step(self.x, &self.params);

        // the actual random number in [0,1)
        self.x as f64 / self.params.m as f64
    }

    /// Get the current state of the generator (`x_k` of [`congruent_random_number_generator_step`])
    pub fn current_state(&self) -> i128 {
        self.x
    }

    pub fn params(&self) -> Parameters {
        self.params
    }
}

/// Parameters of the congruent random number generator [`Generator`]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct Parameters {
    /// "modulus"
    pub m: i128,

    /// "multiplier"
    pub a: i128,

    /// "increment"
    ///
    /// when `c = 0` the generator is called "multiplicative congruential generator"
    pub c: i128,
}

impl Parameters {
    /// Original Lehmer implementation 1949 working on ENIAC which was indeed a 8-decimal digit number machine
    pub const LEHMER: Parameters = Parameters {
        m: (10 as i128).pow(8) + 1,
        a: 23,
        c: 0,
    };

    /// Park-Miller 1988
    pub const PARK_MILLER_1988: Parameters = Parameters {
        m: 2147483647, // 2^31 - 1  // this is a Mersenne prime
        a: 16807,
        c: 0,
    };

    /// Park-Miller 1993 (AKA [**MINSTD**](https://en.wikipedia.org/wiki/Lehmer_random_number_generator))
    pub const PARK_MILLER_1993: Parameters = Parameters {
        m: 2147483647, // 2^31 - 1  // this is a Mersenne prime
        a: 48271,
        c: 0,
    };

    /// Get the name of the parameters, if known
    ///
    /// In this module we provide some pre-defined parameters, this function returns their name if the parameters matches any of them
    ///
    /// # Example
    /// ```
    /// use codici_mod_0::congruent_random_number_generator::*;
    /// assert_eq!(Parameters::LEHMER.name(), Some("Lehmer"));
    /// assert_eq!(Parameters{m: 1, a: 2, c: 3}.name(), None);
    /// ```
    pub fn name(&self) -> Option<&'static str> {
        match self {
            &Parameters::LEHMER => Some("Lehmer"),
            &Parameters::PARK_MILLER_1988 => Some("Park-Miller 1988"),
            &Parameters::PARK_MILLER_1993 => Some("MINSTD - Park-Miller 1993"),
            _ => None,
        }
    }
}

// We use `PARK_MILLER_1993` as default as it seems to be the best,
// lehmer provides strong correlations for the first 3-4 numbers with seed 2
impl Default for Parameters {
    fn default() -> Self {
        Self::PARK_MILLER_1993
    }
}