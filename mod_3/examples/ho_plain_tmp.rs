use std::io::Write;

use mod_3::{LatticeStructure, Lattice};
use nm4p_common::{rand::SeedableRng, data_strem_writer::DataStreamer, entry};
use nm4p_common::serde;


// H = p^2/2m + 1/2 m omega^2 x^2 = 1/2 m (p^2 + omega^2 x^2)
pub struct HO {
    hbar: f64,
    beta: f64,
    omega: f64,
    m: f64,
}

impl HO {
    fn v(&self, x: f64) -> f64 {
        self.m * self.omega.powi(2) * x.powi(2) / 2.0// + x.powi(4)
        //x.powi(10)
    }

    fn local_euclid_action(
        x_0: f64,
        x_1: f64,
        lattice: &Lattice<Self>
    ) -> f64 {
        let s = lattice.structure();
        let v = |x: f64| s.v(x);

        // lattice spacing
        let a = s.beta * s.hbar / lattice.time_div() as f64;

        v(x_0) * a + (x_1 - x_0).powi(2) * s.m / (2.0 * a)
        //v(x_0) * a
    }
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

    fn guesses_for_slice<R: nm4p_common::rand::prelude::Rng>(lattice: &mod_3::Lattice<Self>, time_index: usize) -> impl FnMut(&mod_3::Lattice<Self>, &mut R) -> Option<Self::Guess> + 'static {
        //let s = lattice.structure();
        let delta = 0.05; // TODO !!!

        let mut guess = std::iter::once(());
        move |lattice, rng| guess.next().map(|_| lattice.at(time_index) + delta * (2.0 * rng.gen::<f64>() - 1.0))
    }

    fn delta_euclid_action(lattice: &mod_3::Lattice<Self>, time_index: usize, trial: &Self::Guess) -> f64 {
        let s = lattice.structure();
        let x = |i: isize| *lattice.at_pbc(i);
        let i = time_index as isize;
        let x_trial = *trial;

        //let delta_v = (v(x_trial) - v(x(i))) * a;

        //let delta_k = {
        //    (x_trial.powi(2) - x(i).powi(2) + (x(i - 1) + x(i + 1)) * (x(i) - x_trial)) * s.m
        //};
        //let delta_k = delta_k / a;

        //(delta_v + delta_k) / s.hbar

        let se = |x_i: f64| {
            let mut sum = 0.0;
            if i < lattice.time_div()  as isize - 1 || false {
                sum += Self::local_euclid_action(
                    x_i,
                    x(i + 1),
                    lattice
                );
            }
            if i > 0 || false {
                sum += Self::local_euclid_action(
                    x(i - 1),
                    x_i,
                    lattice
                );
            }
            sum
        };

        let se_old = se(x(i));

        let se_new = se(x_trial);

        //println!("{} {} diff {}", se_old, se_new, se_new - se_old);

        (se_new - se_old) / s.hbar
    }

    fn accept_guess(lattice: &mut mod_3::Lattice<Self>, time_index: usize, trial: Self::Guess) {
        *lattice.at_mut(time_index) = trial;
    }
}

const N_REP: usize = 1000000000;
const TIME_DIV: usize = 100;
const MEASURE_EVERY: usize = 1000;

fn main() {
    let mut lattice = Lattice::new_zeroed(
        HO {
            hbar: 1.0,
            beta: 10.1,
            omega: 1.0,
            m: 1.0,
        },
        TIME_DIV,
    );

    let mut rng = nm4p_common::rand::rngs::StdRng::seed_from_u64(42);

    let file = std::fs::File::create("b.txt").unwrap();
    let mut file = std::io::BufWriter::new(file);

    let mut streamer = DataStreamer::new(
        "common/examples/yy.yaml",
        "ciao",
        entry! {
            a: &'static str = "ciao",
        },
    );

    for i in 0..N_REP {
        let acc = lattice.metropolis_macro_step(&mut rng);

        let x = lattice.iter_time_slices().sum::<f64>() / lattice.time_div() as f64;
        let x2 = lattice.iter_time_slices().map(|y| y.powi(2)).sum::<f64>() / lattice.time_div() as f64;
        let k_naive = (0..lattice.time_div())
            .map(|site| {
                let site = site as isize;
                ((lattice.at_pbc(site + 1) - lattice.at_pbc(site)) / (lattice.structure().beta * lattice.structure().hbar / lattice.time_div() as f64)).powi(2) * lattice.structure().m / 2.0
            })
            .sum::<f64>() / lattice.time_div() as f64;
        let k_virial = (0..lattice.time_div())
            .map(|site| {
                let c = lattice.at_pbc(site as isize);
                c.powi(2) * lattice.structure().m * lattice.structure().omega.powi(2)
            })
            .sum::<f64>() / lattice.time_div() as f64;

        let s = lattice.structure();
        let a = s.beta * s.hbar / lattice.time_div() as f64;
        let x_dot = (lattice.at_pbc(1) - lattice.at_pbc(0)) / a;
        let p2_corrected = s.m * s.hbar / a - s.m * x_dot.powi(2);

        let x = lattice.at(0);
        let z = lattice.at_pbc(-1);

        if i % MEASURE_EVERY == 0 {
            //println!("{} {} {} {} {}", x, x2, k_naive, k_virial, acc);
            //println!("{}", x2);
            //writeln!(file, "{}", x2 + k_naive * 1.0).unwrap();
            //writeln!(file, "{}", 0.5 * s.m * s.omega.powi(2) * lattice.at(0).powi(2) + k_corrected).unwrap();
            writeln!(file, "{}    {}", x, z).unwrap();
            file.flush().unwrap();
            //writeln!(file, "{}", lattice.at(0)).unwrap();
            // flush
            //file.flush().unwrap();
            //streamer.write(entry! {
            //    x: f64 = x,
            //    x2: f64 = x2,
            //    k_naive: f64 = k_naive,
            //    k_virial: f64 = k_virial,
            //    //acc: bool = acc,
            //});
            //streamer.flush();
        }
    }
}