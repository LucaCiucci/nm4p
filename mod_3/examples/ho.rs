//#![allow(unused)]
//#![allow(unused_variables)]

use mod_3::{Lattice, LatticeStructure};
use nm4p_common::rand::{self, SeedableRng};


const N_REP: usize = 10000;
const TIME_DIV: usize = 100;

/// beta hbar omega
const SIM_BETA: f64 = 0.1;

const MEASURE_EVERY: usize = 10;

fn main() {
    let mut rng = rand::rngs::StdRng::seed_from_u64(42);

    let sim_beta = SIM_BETA;
    let eta = sim_beta / TIME_DIV as f64;

    let mut lattice = Lattice::new_zeroed(
        HO {
            eta,
        },
        TIME_DIV,
    );

    for i in 0..N_REP {
        metropolis(
            &mut lattice,
            &mut rng
        );

        let x = lattice.iter_time_slices().sum::<f64>() / lattice.time_div() as f64;
        let x2 = lattice.iter_time_slices().map(|y| y.powi(2)).sum::<f64>() / lattice.time_div() as f64;
        let k_naive = (0..lattice.time_div())
            .map(|site| {
                let site = site as isize;
                (lattice.at_pbc(site + 1) - lattice.at_pbc(site)).powi(2) / (2.0 * eta)
            })
            .sum::<f64>() / eta;
        let k_virial = (0..lattice.time_div())
            .map(|site| {
                let c = lattice.at_pbc(site as isize);
                c.powi(2) * (2.0 * eta) * TIME_DIV as f64
            })
            .sum::<f64>();

        if i % MEASURE_EVERY == 0 {
            println!("{} {} {} {}", x, x2, k_naive, k_virial);
        }
    }
}

pub struct HO {
    eta: f64,
}

impl LatticeStructure for HO {
    type ConstSlice<'a> = &'a f64;
    type MutSlice<'a> = &'a mut f64;
    type Guess = f64;

    fn n(&self) -> usize {
        1
    }

    fn time_slice<'a>(slice: &'a [f64]) -> Self::ConstSlice<'a> {
        &slice[0]
    }

    fn time_slice_mut<'a>(slice: &'a mut [f64]) -> Self::MutSlice<'a> {
        &mut slice[0]
    }

    fn guesses_for_slice<R: rand::prelude::Rng>(&self, time_index: usize) -> impl FnMut(&Lattice<Self>, &mut R) -> Option<Self::Guess> + 'static {
        // TODO 10???
        let delta = 10.0 * self.eta.sqrt();

        let mut guess = std::iter::once(());
        move |lattice, rng| guess.next().map(|_| lattice.at(time_index) + delta * (2.0 * rng.gen::<f64>() - 1.0))
    }

    fn delta_euclid_action(lattice: &Lattice<Self>, time_index: usize, trial: &Self::Guess) -> f64 {
        let eta = lattice.structure().eta;

        // nearest neighbor sum
        let nn_sum = lattice.at_pbc(time_index as isize + 1) + lattice.at_pbc(time_index as isize - 1);

        let partial_e = |y: f64| y.powi(2) * (eta / 2.0 + 1.0 / eta) - 1.0 / eta * nn_sum * y;

        partial_e(*trial) - partial_e(*lattice.at(time_index))
    }

    fn accept_guess(lattice: &mut Lattice<Self>, time_index: usize, trial: Self::Guess) {
        *lattice.at_mut(time_index) = trial;
    }
}

fn metropolis(
    lattice: &mut Lattice<HO>,
    rng: &mut impl rand::Rng,
) {
    lattice.metropolis_macro_step(rng);

    //for time_index in 0..lattice.time_div() {
    //    let y = lattice.at(0);
    //    let y_trial = HO::guess(lattice, time_index, rng);
    //    let delta_energy = HO::delta_energy(lattice, time_index, &y_trial);
//
    //    if delta_energy < 0.0 {
    //        *lattice.at_mut(time_index) = y_trial;
    //    } else {
    //        let prob = (-delta_energy).exp();
    //        if rng.gen::<f64>() < prob {
    //            *lattice.at_mut(time_index) = y_trial;
    //        }
    //    }
    //}
}
