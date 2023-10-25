use std::borrow::Borrow;

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

    (
        e_x,
        (e_x2 - e_x.powi(2)) * count / (count - T::from_usize(1).unwrap()),
    ) // TODO this is wrong! this is biased. Must use Bessel's correction
      //(e_x, e_x2 - e_x.powi(2)) // TODO this is wrong! this is biased. Must use Bessel's correction
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

pub fn autocorr_plain<'a>(x: &'a [f64]) -> impl Iterator<Item = f64> + 'a {
    #[allow(non_snake_case)]
    let N = x.len();

    let (mu, var) = mean_var(x.iter().cloned());

    (0..).map(move |k| {
        assert!(k < N);

        let x_k = x.iter().skip(k);
        let x = x.iter();

        x.zip(x_k)
            .map(|(x_i, x_i_k)| (x_i - mu) * (x_i_k - mu))
            .sum::<f64>()
            / (var * (N - k) as f64)
    })
}

pub fn autocorr_fft(x: &[f64]) -> Vec<f64> {
    #[allow(non_snake_case)]
    let N = x.len();
    let padding = N;

    let mean = x.iter().sum::<f64>() / N as f64;

    let mut xx = x
        .iter()
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

    c.into_iter().skip(1).enumerate().map({
        let mut sum = 0.0;
        move |(k, x)| {
            sum += x * if corrected {
                1.0 - k as f64 / N as f64
            } else {
                1.0
            };
            sum
        }
    })
}

pub fn autocorr_int(x: &[f64], corrected: bool) -> impl Iterator<Item = f64> {
    autocorr_int_inner(autocorr_fft(x).into_iter(), corrected)
}

pub enum RoughTauIntEstimationMethod {
    Normal,
    Derivative,
    SumSubsequent,
}

pub fn estimate_rough_tau_int_impl(
    x: &[f64],
    method: RoughTauIntEstimationMethod,
) -> Option<(usize, f64)> {
    //#[allow(non_snake_case)]
    //let N = x.len();

    let autocorr = autocorr_fft(x);
    let autocorr_int = autocorr_int_inner(autocorr.iter().cloned(), false).collect::<Vec<_>>(); // TODO maybe false???

    #[allow(non_snake_case)]
    let M = match method {
        RoughTauIntEstimationMethod::Normal => {
            autocorr
                .iter()
                .cloned()
                .enumerate()
                .find(|(_, c)| *c < 0.0)?
                .0
        }
        RoughTauIntEstimationMethod::Derivative => {
            autocorr
                .iter()
                .cloned()
                .zip(autocorr.iter().cloned().skip(1))
                .enumerate()
                .find(|(_, (c_1, c_2))| *c_2 > *c_1)?
                .0
        }
        RoughTauIntEstimationMethod::SumSubsequent => {
            autocorr
                .iter()
                .cloned()
                .zip(autocorr.iter().cloned().skip(1))
                .enumerate()
                .find(|(_, (c_1, c_2))| (*c_1 + *c_2) < 0.0)?
                .0
        }
    };

    Some((M, autocorr_int[M]))
}

pub fn estimate_rough_tau_int(x: &[f64]) -> Option<f64> {
    estimate_rough_tau_int_impl(x, RoughTauIntEstimationMethod::SumSubsequent)
        .map(|(_m, tau_int)| tau_int)
}

pub fn binning<'a>(x: &'a [f64], k: usize) -> (usize, impl Iterator<Item = f64> + 'a) {
    let n = x.len();
    let n_out = n / k;

    let bins = (0..n_out).map(move |i| {
        let i = i * k;
        let j = i + k;

        x[i..j].iter().sum::<f64>() / k as f64
    });

    (n_out, bins)
}

#[derive(Debug, Clone)]
pub struct LogBinningVarResultBin {
    pub k: usize,
    pub var: f64,
    pub count: usize,
}

#[derive(Debug, Clone)]
pub struct LogBinningVarResult {
    pub count: usize,
    pub mean: f64,
    pub var: f64,
    pub binning: Vec<LogBinningVarResultBin>,
}

pub fn logarithmic_binning_variance<I>(x: I) -> LogBinningVarResult
where
    I: IntoIterator,
    I::Item: Borrow<f64>,
{
    struct Bin {
        k: usize,
        x2_sum: f64,
        count: usize,
        x_tail: Option<f64>,
    }
    impl Bin {
        fn new(k: usize) -> Self {
            Self {
                k,
                x2_sum: 0.0,
                count: 0,
                x_tail: None,
            }
        }
    }

    let mut bins = Vec::<Bin>::new();

    fn get_bin_at(bins: &mut Vec<Bin>, index: usize, k: usize) -> &mut Bin {
        assert!(index <= bins.len());
        if index == bins.len() {
            // note: this push could, in theory make the algorithm be O(N (log N)^2) but, in practice, the number of bins is small enough that this is not a problem. Swapping the Vec for a LinkedList would make this O(N log N) but would be probably slower in practice
            bins.push(Bin::new(k));
        }
        &mut bins[index]
    }

    fn push(x: f64, bins: &mut Vec<Bin>, at: usize, k: usize) {
        let bin = get_bin_at(bins, at, k);
        bin.x2_sum += x.powi(2);
        bin.count += 1;
        if let Some(x_tail) = bin.x_tail.take() {
            push((x_tail + x) / 2.0, bins, at + 1, k * 2);
        } else {
            bin.x_tail = Some(x);
        }
    }

    let mut sum_x = 0.0;
    let mut sum_x2 = 0.0;
    let mut count = 0;
    for x in x {
        let x = x.borrow();
        push(*x, &mut bins, 0, 1);
        sum_x += x;
        sum_x2 += x.powi(2);
        count += 1;
    }

    let mean_x = sum_x / count as f64;
    let squared_mean_x = mean_x.powi(2);
    let var_x = (sum_x2 / count as f64 - squared_mean_x) * count as f64 / (count as f64 - 1.0);

    let binning = bins
        .into_iter()
        .map(|bin| {
            let var = (bin.x2_sum / bin.count as f64 - squared_mean_x) * bin.count as f64
                / (bin.count as f64 - 1.0);
            LogBinningVarResultBin {
                k: bin.k,
                var,
                count: bin.count,
            }
        })
        .collect();

    LogBinningVarResult {
        count,
        mean: mean_x,
        var: var_x,
        binning,
    }
}

pub fn estimate_tau_int(x: &[f64]) -> Option<f64> {
    const FACTOR: f64 = 10.0; // TODO !!!

    let log_binning = logarithmic_binning_variance(x);

    let var_mu_sample = log_binning.var / log_binning.count as f64;

    let esss_over_n = log_binning.binning.iter().map(|level| {
        let var_mu_level = level.var / level.count as f64;
        let ess_over_n = var_mu_level / var_mu_sample;
        ess_over_n
    });

    // the corresponding k is 2^(index + 1)
    let esss_over_n_bc = esss_over_n
        .clone()
        .zip(esss_over_n.skip(1))
        .map(|(ess_over_n_1, ess_over_n_2)| ess_over_n_2 * 2.0 - ess_over_n_1)
        .collect::<Vec<_>>();

    let ess_for_approx_tau_int = move |tau_int: f64| -> f64 {
        let desidered_k = tau_int * FACTOR;
        // k = 2^(index + 1)
        // index = log2(k) - 1
        let desidered_index = desidered_k.log2() - 1.0;
        let index = (desidered_index + 0.5) as usize;
        esss_over_n_bc[index]
    };

    let rough_tau_int = estimate_rough_tau_int(x)?;
    //println!("t1: {}", rough_tau_int);
    let tau_int = tau_int_from_ess_over_n(ess_for_approx_tau_int(rough_tau_int));
    //println!("t2: {}", tau_int);
    let tau_int = tau_int_from_ess_over_n(ess_for_approx_tau_int(tau_int));
    //println!("t3: {}", tau_int);

    Some(tau_int)
}

pub fn tau_int_from_ess_over_n(ess_over_n: f64) -> f64 {
    (ess_over_n - 1.0) / 2.0
}

pub fn ess_over_n_from_tau_int(tau_int: f64) -> f64 {
    tau_int * 2.0 + 1.0
}
