
pub use clap;


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

