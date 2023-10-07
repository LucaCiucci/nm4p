
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

pub fn autocorr_plain<'a>(
    x: &'a [f64],
) -> impl Iterator<Item = f64> + 'a {
    #[allow(non_snake_case)]
    let N = x.len();

    let (mu, var) = mean_var(x.iter().cloned());

    (0..).map(move |k| {
        assert!(k < N);

        let x_k = x.iter().skip(k);
        let x = x.iter();

        x.zip(x_k)
            .map(|(x_i, x_i_k)| (x_i - mu) * (x_i_k - mu))
            .sum::<f64>() / (var * (N - k) as f64)
    })
}

pub fn autocorr_fft(
    x: &[f64],
) -> Vec<f64> {
    #[allow(non_snake_case)]
    let N = x.len();
    let padding = N;

    let mean = x.iter().sum::<f64>() / N as f64;

    let mut xx = x.iter()
        .map(|x| x - mean)
        .chain(std::iter::repeat(0.0).take(padding))
        .map(|x| rustfft::num_complex::Complex::new(x, 0.0))
        .collect::<Vec<_>>();

    let mut planner = rustfft::FftPlanner::new();
    let fft = planner.plan_fft_forward(xx.len());
    // let ifft = planner.plan_fft_inverse(xx.len()); see below

    fft.process(&mut xx);

    for x in xx.iter_mut() {
        *x = *x * x.conj();
    }

    // NOTE: since we expect a real output, we can use fft instead of ifft
    // and save some resources
    fft.process(&mut xx);

    // take real part and normalize
    let xx = xx.iter().map(|x| x.re / xx[0].re).take(N);

    // counting factor (N - k)
    let xx = xx.enumerate().map(|(k, x)| x * N as f64 / (N - k) as f64);

    xx.take(N).collect()
}