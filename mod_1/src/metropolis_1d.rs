use nm4p_common::rand;
use rand::{Rng, RngCore};

// Metropolis Hastings algorithm for 1D distributions
pub struct MH1D<T, K> {
    target: T,
    x: f64,
    proposal_kernel: K,
}

impl<T, K> MH1D<T, K>
where
    T: Target,
    K: ProposalKernel,
{
    pub fn new(
        target: T,
        x_0: f64,
        proposal_kernel: K,
    ) -> Self {
        Self {
            target,
            x: x_0,
            proposal_kernel,
        }
    }

    /// Perform a single step of the metropolis algorithm
    ///
    /// Links:
    /// - original paper: <https://bayes.wustl.edu/Manual/EquationOfState.pdf>
    /// - <https://arxiv.org/pdf/1504.01896.pdf>
    ///
    /// # Returns
    /// The new value of `x` and whether the step was accepted. The user
    /// could perform some optimization by re-evaluating quantities
    /// only if the step is accepted.
    pub fn step(&mut self, rng: &mut dyn RngCore) -> (f64, bool) {
        let (proposal, proposal_ratio) = self.proposal_kernel.propose(self.x, rng);
        assert!(proposal.is_finite());

        let ratio = self.target.probability_ratio(proposal, self.x);
        let accept = self.true_with_probability(ratio * proposal_ratio, rng);

        if accept {
            self.x = proposal;
        }

        (self.x, accept)
    }

    pub fn iter(self, rng: &mut dyn RngCore) -> MH1DIterator<T, K> {
        MH1DIterator {
            mh: self,
            rng,
        }
    }

    /// Returns true with probability `p`
    fn true_with_probability(&mut self, p: f64, rng: &mut dyn RngCore) -> bool {
        assert!(p.is_finite());
        assert!(p >= 0.0);

        if p >= 1.0 {
            true
        } else {
            rng.gen::<f64>() < p
        }
    }
}

/// A target distribution for the metropolis algorithm
pub trait Target {
    fn probability_ratio(&self, x_test: f64, x: f64) -> f64;
}

impl<F: Fn(f64) -> f64> Target for F {
    fn probability_ratio(&self, x_test: f64, x: f64) -> f64 {
        let p = self(x);
        let p_test = self(x_test);

        assert!(p.is_finite());
        assert!(p_test.is_finite());
        assert!(p > 0.0);

        p_test / p
    }
}

pub trait ProposalKernel {
    /// Proposes a new value `x'` given the current value and the
    /// Ratio `A_(x' x) / A_(x x')`
    fn propose(&mut self, x: f64, rng: &mut dyn RngCore) -> (f64, f64);
}

pub struct MH1DIterator<'a, T, G> {
    mh: MH1D<T, G>,
    rng: &'a mut dyn RngCore,
}

impl<'a, T, G> Iterator for MH1DIterator<'a, T, G>
where
    T: Target,
    G: ProposalKernel,
{
    type Item = (f64, bool);

    fn next(&mut self) -> Option<Self::Item> {
        Some(self.mh.step(self.rng))
    }
}

pub mod kernels {
    use super::*;

    /// A proposal kernel that proposes a new value `x'` by sampling from a uniform
    /// distribution centered in `x` with width `delta`
    pub struct UniformKernel {
        /// The width of the uniform distribution
        delta: f64,
    }

    impl UniformKernel {
        pub fn new(delta: f64) -> Self {
            assert!(delta > 0.0);
            Self { delta }
        }
    }

    impl ProposalKernel for UniformKernel {
        fn propose(&mut self, x: f64, rng: &mut dyn RngCore) -> (f64, f64) {
            (
                x + self.delta * (rng.gen::<f64>() - 0.5),
                1.0,
            )
        }
    }
}