
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

    (e_x, e_x2 - e_x.powi(2)) // TODO this is wrong! this is biased. Must use Bessel's correction
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

pub fn autocorr_int_inner<'a>(
    c: impl Iterator<Item = f64> + Clone + 'a,
    corrected: bool,
) -> impl Iterator<Item = f64> + 'a {
    #[allow(non_snake_case)]
    let N = c.clone().count();

    c
        .into_iter()
        .enumerate()
        .map({
            let mut sum = 0.0;
            move |(k, x)| {
                sum += x * if corrected { 1.0 - k as f64 / N as f64 } else { 1.0 };
                sum
            }
        })
}

pub fn autocorr_int(
    x: &[f64],
    corrected: bool,
) -> impl Iterator<Item = f64> {
    autocorr_int_inner(
        autocorr_fft(x).into_iter(),
        corrected
    )
}

#[derive(Debug, Clone, Copy)]
pub enum EstimateRoughTauIntMethod {
    AutocorrCrossesZero,
    AutocorrDerivativeCrossesZero,
}

#[derive(Debug, Clone, Copy)]
pub struct EstimateRoughTauIntOptions {
    pub method: EstimateRoughTauIntMethod,
    pub min_multiplier: usize,
}

impl Default for EstimateRoughTauIntOptions {
    fn default() -> Self {
        Self {
            method: EstimateRoughTauIntMethod::AutocorrDerivativeCrossesZero,
            min_multiplier: 10,
        }
    }
}

pub fn estimate_rough_tau_int_impl(
    x: &[f64],
    on_derivative: bool,
    min_multiplier: usize,
) -> Option<(usize, f64)> {
    #[allow(non_snake_case)]
    let N = x.len();

    let autocorr = autocorr_fft(x);
    let autocorr_int = autocorr_int_inner(autocorr.iter().cloned(), false).collect::<Vec<_>>();

    #[allow(non_snake_case)]
    let M = if on_derivative {
        autocorr
            .iter()
            .cloned()
            .zip(autocorr.iter().cloned().skip(1))
            .enumerate()
            .find(|(_, (c_1, c_2))| *c_2 > *c_1)?.0
    } else {
        autocorr
            .iter()
            .cloned()
            .enumerate()
            .find(|(_, c)| *c < 0.0)?.0
    };

    if M * min_multiplier < N {
        Some((M, autocorr_int[M]))
    } else {
        None
    }
}

pub fn estimate_rough_tau_int(
    x: &[f64],
) -> Option<f64> {
    let (_m, tau_int) = estimate_rough_tau_int_impl(
        x,
        false,
        1,
    )?;
    if tau_int as usize <= x.len() / 100 {
        Some(tau_int)
    } else {
        None
    }
}