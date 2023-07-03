
// Note:
//   fortran    rust
//    real*4 -> f32
// integer*4 -> i32
//      real -> f32/f64 (compiler dependent)

pub struct Ran2 {
    params: Ran2Params,
    state: Ran2State,
}

impl Default for Ran2 {
    fn default() -> Self {
        Self::default_with_seed(1)
    }
}

impl Ran2 {
    /// Creates and initializes a generator
    ///
    /// In ran2, this was done when a negative value was passed as the `idum`.
    ///
    /// See [`Ran2::default`] or [`Ran2::default_with_seed`] for a more convenient way to create a generator.
    pub fn new(seed: u32, params: Ran2Params) -> Self {
        assert!(seed > 0, "seed must be positive");

        let mut idum = seed as i32;
        let idum2 = idum;
        let mut iv = vec![0; params.n_tab as usize];

        for j in (0..(params.n_tab + 8)).rev() {
            let k = idum / params.iq_1;
            idum = params.ia_1 * (idum - k * params.iq_1) - k * params.ir_1;
            if idum < 0 {
                idum += params.im_1;
            }
            if j < params.n_tab {
                iv[j as usize] = idum;
            }
        }
        let iy = iv[0];

        Self {
            params,
            state: Ran2State {
                idum,
                iv,
                idum2,
                iy,
            },
        }
    }

    pub fn default_with_seed(seed: u32) -> Self {
        Self::new(seed, Ran2Params::default())
    }

    pub fn generate(&mut self) -> f32 {
        self.step();
        (self.state.iy as f32 * self.params.am).min(self.params.rnmx)
    }

    /// Advance the state of the generator
    fn step(&mut self) {
        let state = &mut self.state;
        let params = &self.params;

        fn update(idum: &mut i32, ia: i32, iq: i32, ir: i32, im: i32) {
            let k = *idum / iq;
            *idum = ia * (*idum - k * iq) - k * ir;
            if *idum < 0 {
                *idum += im;
            }
        }

        update(&mut state.idum, params.ia_1, params.iq_1, params.ir_1, params.im_1);
        update(&mut state.idum2, params.ia_2, params.iq_2, params.ir_2, params.im_2);

        let j = state.iy / params.n_div;
        state.iy = state.iv[j as usize] - state.idum2;
        state.iv[j as usize] = state.idum;
        if state.iy < 1 {
            state.iy += params.imm_1;
        }
    }
}

pub struct Ran2State {
    pub idum: i32,
    pub iv: Vec<i32>,
    pub idum2: i32,
    pub iy: i32,
}

impl Ran2State {
}

pub struct Ran2Params {
    pub im_1: i32,
    pub im_2: i32,
    pub am: f32,
    pub imm_1: i32,
    pub ia_1: i32,
    pub ia_2: i32,
    pub iq_1: i32,
    pub iq_2: i32,
    pub ir_1: i32,
    pub ir_2: i32,
    pub n_tab: i32,
    pub n_div: i32,
    pub eps: f32,
    pub rnmx: f32,
}

impl Default for Ran2Params {
    fn default() -> Self {
        Self::default_with_n_tab(32)
    }
}

impl Ran2Params {
    /// Creates a new set of parameters with the given `n_tab`.
    ///
    /// In the original fortran code, the default value of `n_tab` was 32.
    ///
    /// Note that the generator initialization is O(n_tab^2)!
    pub fn default_with_n_tab(n_tab: u32) -> Self {
        assert!(n_tab > 0, "n_tab must be positive");

        let im_1 = 2147483563;
        let imm_1= im_1 - 1;
        let n_tab = n_tab as i32;
        let eps = 1.2e-7;
        Self {
            im_1,
            im_2: 2147483399,
            am: 1.0 / im_1 as f32,
            imm_1,
            ia_1: 40014,
            ia_2: 40692,
            iq_1: 53668,
            iq_2: 52774,
            ir_1: 12211,
            ir_2: 3791,
            n_tab,
            n_div: 1 + imm_1 / n_tab,
            eps,
            rnmx: 1.0 - eps,
        }
    }
}