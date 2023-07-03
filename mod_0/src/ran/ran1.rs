

pub struct Ran1 {
    state: Ran1State,
    params: Ran1Params,
}

impl Default for Ran1 {
    fn default() -> Self {
        Self::default_with_seed(1)
    }
}

impl Ran1 {
    pub fn new(seed: u32, params: Ran1Params) -> Self {
        assert!(seed > 0, "seed must be positive");

        let mut idum = seed as i32;
        let mut iv = vec![0; 32];

        for j in (0..(params.n_tab + 8)).rev() {
            let k = idum / params.iq;
            idum = params.ia * (idum - k * params.iq) - k * params.ir;
            if idum < 0 {
                idum += params.im;
            }
            if j < params.n_tab {
                iv[j as usize] = idum;
            }
        }
        let iy = iv[0];

        Self {
            params,
            state: Ran1State {
                idum,
                iv,
                iy,
            },
        }
    }

    pub fn default_with_seed(seed: u32) -> Self {
        Self::new(seed, Ran1Params::default())
    }

    pub fn generate(&mut self) -> f32 {
        self.step();
        (self.state.iy as f32 * self.params.am).min(self.params.rnmx)
    }

    fn step(&mut self) {
        let k = self.state.idum / self.params.iq;
        self.state.idum = self.params.ia * (self.state.idum - k * self.params.iq) - k * self.params.ir;
        if self.state.idum < 0 {
            self.state.idum += self.params.im;
        }
        let j = self.state.iy / self.params.n_div;
        self.state.iy = self.state.iv[j as usize];
        self.state.iv[j as usize] = self.state.idum;
    }
}

pub struct Ran1State {
    idum: i32,
    iv: Vec<i32>,
    iy: i32,
}

pub struct Ran1Params {
    pub ia: i32,
    pub im: i32,
    pub am: f32,
    pub iq: i32,
    pub ir: i32,
    pub n_tab: i32,
    pub n_div: i32,
    pub eps: f32,
    pub rnmx: f32,
}

impl Default for Ran1Params {
    fn default() -> Self {
        Self::default_with_n_tab(32)
    }
}

impl Ran1Params {
    /// Creates a new set of parameters with the given `n_tab`.
    ///
    /// In the original fortran code, the default value of `n_tab` was 32.
    ///
    /// Note that the generator initialization is O(n_tab^2)!
    pub fn default_with_n_tab(n_tab: u32) -> Self {
        assert!(n_tab > 0, "n_tab must be positive");
        let im = 2147483647;

        Self {
            ia: 16807,
            im,
            am: 1.0 / im as f32,
            iq: 127773,
            ir: 2836,
            n_tab: n_tab as i32,
            n_div: 1 + (im - 1) / n_tab as i32,
            eps: 1.2e-7,
            rnmx: 1.0 - 1.2e-7,
        }
    }
}