use nm4p_common::{
    indicatif, rand, rand_distr,
    stat::{estimate_tau_int, mean_var},
};
use rand::{prelude::Distribution, SeedableRng};

const TAU_EXP: f64 = 10.0;
const N: usize = 1_000_000;
const N_REPETITIONS: usize = 100;

fn main() {
    let mut rng = rand::rngs::StdRng::seed_from_u64(420);

    let tau_exp: f64 = TAU_EXP;
    let tau_int = (-1.0 / tau_exp).exp() / (1.0 - (-1.0 / tau_exp).exp());

    let mut evaluations = Vec::new();

    let bar = indicatif::ProgressBar::new(N_REPETITIONS as u64);

    for _ in 0..N_REPETITIONS {
        bar.inc(1);
        let samples = make_samples(tau_exp, N, &mut rng);
        let estimated_tau_int = estimate_tau_int(&samples);
        evaluations.push(estimated_tau_int.unwrap());
    }
    drop(bar);

    let (mean, var) = mean_var(evaluations.iter().cloned());
    println!(
        "estimated tau_int: {} ± {} (with std dev: {}), expected: {}",
        mean,
        (var / evaluations.len() as f64).sqrt(),
        var.sqrt(),
        tau_int
    );

    let doc = format!(
        r##"
estimated: {}
uncertainty: {}
std_dev: {}
expected: {}
"##,
        mean,
        (var / evaluations.len() as f64).sqrt(),
        var.sqrt(),
        tau_int,
    );

    std::fs::write("mod_1/img/plots/test-tau-int-estimate.yaml", doc).unwrap();
}

fn make_samples(tau: f64, n: usize, rng: &mut impl rand::Rng) -> Vec<f64> {
    (0..n)
        .map({
            let a = (-1.0 / tau).exp();
            let b = (1.0 - a.powi(2)).sqrt();
            let normal = rand_distr::Normal::new(0.0, 1.0).unwrap();
            let mut last = normal.sample(rng);
            move |_| {
                let y = normal.sample(rng);
                let x = a * last + b * y;
                last = x;
                x
            }
        })
        .collect()
}
