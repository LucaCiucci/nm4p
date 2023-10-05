
use num_traits::{Float, FromPrimitive};

/// Computes the mean and variance of the iterator.
///
/// The variance is defined as:
/// `E[(X - E[X])^2] = E[X^2] - 2*E[X]*E[X] + E[X]^2 = E[X^2] - E[X]^2`
#[must_use]
pub fn mean_var<T, I>(values: I) -> (T, T)
where
    T: Float + FromPrimitive,
    I: IntoIterator<Item = T>,
{
    let (sum_x2, sum_x, count) = values.into_iter().fold(
        (T::zero(), T::zero(), 0usize),
        |(sum_x2, sum_x, count), x| (sum_x2 + x.powi(2), sum_x + x, count + 1),
    );

    let count = T::from_usize(count).unwrap();

    let e_x2 = sum_x2 / count;
    let e_x = sum_x / count;

    (e_x, e_x2 - e_x.powi(2))
}

/// Computes the variance of the iterator.
///
/// See [`mean_var`] for more details.
#[must_use]
pub fn var<T, I>(values: I) -> T
where
    T: Float + FromPrimitive,
    I: IntoIterator<Item = T>,
{
    mean_var(values).1
}