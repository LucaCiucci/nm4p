use nm4p_common::rand::Rng;



/// A lattice of sites
///
/// ```text
/// ^"time"
/// | *---*---*---*---*---*---*
/// | |   |   |   |   |   |   |
/// | *---*---*---*---*---*---*
/// | |   |   |   |   |   |   |
/// | *---*---*---*---*---*---*
/// | |   |   |   |   |   |   |
/// | *---*---*---*---*---*---*
/// | |   |   |   |   |   |   |
/// | *---*---*---*---*---*---*
/// | |   |   |   |   |   |   |
/// | *---*---*---*---*---*---*
/// | |   |   |   |   |   |   |
/// | *---*---*---*---*---*---*
/// | |   |   |   |   |   |   |
/// | *---*---*---*---*---*---*
/// +--------------------------->
///                 "coordinates"
/// ```
pub struct Lattice<S>
{
    structure: S,

    time_div: usize,

    data: Vec<f64>,
}

impl<S: LatticeStructure> Lattice<S> {
    /// Create a new lattice with all sites set to zero
    ///
    /// # Arguments
    /// * `structure` - Lattice structure
    /// * `time_div` - Number of time divisions
    pub fn new_zeroed(structure: S, time_div: usize) -> Self {
        let count = structure.n() * time_div;
        Lattice {
            structure,
            time_div,
            data: Vec::from_iter((0..count).map(|_| 0.0)),
        }
    }

    pub fn structure(&self) -> &S {
        &self.structure
    }

    /// Number of time divisions
    pub fn time_div(&self) -> usize {
        self.time_div
    }

    /// Get the data slice at a given time index
    pub fn data_at(&self, time_index: usize) -> &[f64] {
        let n = self.structure.n();
        let start = time_index * n;
        &self.data[start..start + n]
    }

    /// Get the data slice at a given time index
    pub fn data_at_mut(&mut self, time_index: usize) -> &mut [f64] {
        let n = self.structure.n();
        let start = time_index * n;
        &mut self.data[start..start + n]
    }

    /// Get a time slice
    pub fn at<'s>(&'s self, time_index: usize) -> S::ConstSlice<'s> {
        S::time_slice(self.data_at(time_index))
    }

    /// Get a time slice
    pub fn at_mut<'s>(&'s mut self, time_index: usize) -> S::MutSlice<'s> {
        S::time_slice_mut(self.data_at_mut(time_index))
    }

    /// Get a time slice with periodic boundary conditions
    pub fn at_pbc<'s>(&'s self, time_index: isize) -> S::ConstSlice<'s> {
        let time_index = time_index.rem_euclid(self.time_div as isize) as usize;
        self.at(time_index)
    }

    /// Get a time slice with periodic boundary conditions
    pub fn at_pbc_mut<'s>(&'s mut self, time_index: isize) -> S::MutSlice<'s> {
        let time_index = time_index.rem_euclid(self.time_div as isize) as usize;
        self.at_mut(time_index)
    }

    pub fn iter_time_slices<'s>(&'s self) -> impl Iterator<Item = S::ConstSlice<'s>> {
        (0..self.time_div).map(move |i| self.at(i))
    }

    pub fn metropolis_macro_step<R: Rng>(&mut self, rng: &mut R) -> usize {
        let mut acc = 0;
        for time_index in (0..self.time_div) {
            let mut guesses = S::guesses_for_slice::<R>(self, time_index);
            while let Some(trial) = guesses(self, rng) {
                let delta_se = S::delta_euclid_action(self, time_index, &trial);
                let accept = delta_se < 0.0 || rng.gen::<f64>() < (-delta_se).exp();
                if accept {
                    S::accept_guess(self, time_index, trial);
                    acc += 1;
                }
            }
        }
        acc
    }
}

pub trait LatticeStructure: Sized {
    type ConstSlice<'a>;
    type MutSlice<'a>;
    type Guess;

    fn n(&self) -> usize;

    fn time_slice<'a>(slice: &'a [f64]) -> Self::ConstSlice<'a>;
    fn time_slice_mut<'a>(slice: &'a mut [f64]) -> Self::MutSlice<'a>;
    fn guesses_for_slice<R: Rng>(lattice: &Lattice<Self>, time_index: usize) -> impl FnMut(&Lattice<Self>, &mut R) -> Option<Self::Guess> + 'static;
    fn delta_euclid_action(lattice: &Lattice<Self>, time_index: usize, trial: &Self::Guess) -> f64;
    fn accept_guess(lattice: &mut Lattice<Self>, time_index: usize, trial: Self::Guess);
}

//pub struct MassiveParticle1D<F> {
//    pub mass: f64,
//    pub potential: F,
//}
//
//impl<F: Fn(f64) -> f64> LatticeStructure for MassiveParticle1D<F> {
//    type ConstSlice<'a> = &'a f64;
//    type MutSlice<'a> = &'a mut f64;
//    type Guess<'a> = f64 where Self: 'a;
//
//    fn n(&self) -> usize {
//        1
//    }
//
//    fn time_slice<'a>(slice: &'a [f64]) -> Self::ConstSlice<'a> {
//        &slice[0]
//    }
//
//    fn time_slice_mut<'a>(slice: &'a mut [f64]) -> Self::MutSlice<'a> {
//        &mut slice[0]
//    }
//
//    fn guess<'s>(&'s self, slice: &Self::ConstSlice<'_>) -> Self::Guess<'s> {
//    }
//}