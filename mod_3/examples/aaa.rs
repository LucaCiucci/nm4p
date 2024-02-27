//#![allow(unused)]
//#![allow(unused_variables)]

use mod_3::Lattice;
use nm4p_common::rand::{self, SeedableRng};


const N_REP: usize = 1000000;
const LATTICE_N: usize = 100;

/// beta hbar omega
const SIM_BETA: f64 = 0.1;

const MEASURE_EVERY: usize = 100;

fn main() {
    let mut lattice = Lattice::new_zeroed(
        MassiveParticle1D {
            mass: 1.0,
            potential: |x: f64| x.powi(2) / 2.0,
        },
        LATTICE_N
    );
    let mut rng = rand::rngs::StdRng::seed_from_u64(42);

    let sim_beta = SIM_BETA;
    let eta = sim_beta / lattice.n() as f64;

    for i in 0..N_REP {
        metropolis(
            &mut lattice,
            eta,
            &mut rng
        );

        let x = lattice.iter_time_slices().map(|c| c[0]).sum::<f64>() / lattice.n() as f64;
        let x2 = lattice.iter_time_slices().map(|c| c[0]).map(|y| y.powi(2)).sum::<f64>() / lattice.n() as f64;
        let k_naive = (0..lattice.n())
            .map(|site| {
                let site = site as isize;
                (lattice.get_pbc(site + 1)[0] - lattice.get_pbc(site)[0]).powi(2) / (2.0 * eta)
            })
            .sum::<f64>() / eta;
        let k_virial = (0..lattice.n())
            .map(|site| {
                let c = lattice.get_pbc(site as isize)[0];
                c.powi(2) * (2.0 * eta)
            })
            .sum::<f64>();

        if i % MEASURE_EVERY == 0 {
            println!("{} {} {} {}", x, x2, k_naive, k_virial);
        }
    }
}

fn metropolis<F>(
    lattice: &mut Lattice<MassiveParticle<F>>,
    eta: f64,
    rng: &mut impl rand::Rng,
) {
    // TODO 10???
    let delta = 10.0 * eta.sqrt();

    for site in 0..lattice.n() {
        let y = lattice[site][0];
        let y_trial = y + delta * (2.0 * rng.gen::<f64>() - 1.0);

        // nearest neighbor sum
        let nn_sum = lattice.get_pbc(site as isize + 1)[0] + lattice.get_pbc(site as isize - 1)[0];

        let partial_e = |y: f64| y.powi(2) * (eta / 2.0 + 1.0 / eta) - 1.0 / eta * nn_sum * y;

        let e_old = partial_e(y);
        let e_trial = partial_e(y_trial);

        if e_trial < e_old {
            lattice[site][0] = y_trial;
        } else {
            let prob = (-(e_trial - e_old)).exp();
            if rng.gen::<f64>() < prob {
                lattice[site][0] = y_trial;
            }
        }
    }
}