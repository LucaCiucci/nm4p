use crate::congruent_generator::{CongruentGenerator, Parameters, DEFAULT_SEED};


/// Create a new "`ran0`" generator.
///
/// The generator is a congruent random number generator with parameters
/// [`Parameters::PARK_MILLER_1988`].
pub fn make_ran0() -> CongruentGenerator {
    CongruentGenerator::new(DEFAULT_SEED, Parameters::PARK_MILLER_1988)
}