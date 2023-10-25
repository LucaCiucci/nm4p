pub use clap;
pub use indicatif;
pub use rand;
pub use rand_distr;
pub use rustfft;
pub use yaml_rust;

use std::ops::Deref;

pub mod stat;

pub struct Immutable<T> {
    value: T,
}

impl<T> Immutable<T> {
    pub fn new(value: T) -> Self {
        Immutable { value }
    }
}

impl<T> Deref for Immutable<T> {
    type Target = T;
    fn deref(&self) -> &Self::Target {
        &self.value
    }
}

pub fn lerp<T>(a: T, b: T, t: f64) -> T
where
    T: std::ops::Add<Output = T>
        + std::ops::Sub<Output = T>
        + std::ops::Mul<f64, Output = T>
        + Copy,
{
    a + (b - a) * t
}
