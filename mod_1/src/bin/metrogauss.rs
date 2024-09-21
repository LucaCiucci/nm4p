use std::{fs::File, os::fd::{AsRawFd, FromRawFd}};

use clap::{Parser, ValueEnum};
use nm4p_common::{cli::{parse_expression_x_to_1, CLI_STYLES}, data_stream::DataStreamWriter};
use rand::{rngs::StdRng, Rng, SeedableRng};
use serde::Serialize;

fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    // if no seed is provided, generate a random one (based on the system entropy)
    let seed = args.seed.unwrap_or(rand::thread_rng().gen());

    // create a random number generator
    let mut rng = StdRng::seed_from_u64(seed);

    // parse the distribution function
    let mut target_distribution = args.parse_distribution()?;

    // write the results to stdout in yaml format
    let mut writer = DataStreamWriter::new(unsafe {
        File::from_raw_fd(std::io::stdout().as_raw_fd())
    }).with_header_data("metrogauss", args.clone());

    let mut current = Draw { x: args.x0, acc: 0 };

    for _ in 0..args.n {
        let proposal = current.x + match args.proposal {
            ProposalType::Uniform => rng.gen_range(-args.delta..args.delta),
            ProposalType::Normal => rng.gen::<f64>() * args.delta,
        };

        let p_proposal = target_distribution(proposal)?;
        let p_x = target_distribution(current.x)?;

        if p_x <= 0.0 {
            anyhow::bail!("Unexpected: f({}) = {p_x} <= 0", current.x);
        }

        let accept_probability = (p_proposal / p_x).min(1.0);

        if rng.gen_range(0.0..1.0) < accept_probability {
            current.x = proposal;
            current.acc += 1;
        }

        writer.record(&current);
    }

    Ok(())
}

/// Generate random numbers from a given distribution
/// using the Metropolis algorithm.
///
/// Output is written to stdout in YAML format.
#[derive(Debug, Clone)]
#[derive(Parser, Serialize)]
#[clap(styles=CLI_STYLES)]
struct Args {
    /// Proposal distribution kind
    ///
    /// Note that the proposal distribution depends on the `delta` parameter.
    #[clap(short, long, default_value = "uniform")]
    proposal: ProposalType,

    /// Proposal distribution scale parameter
    #[clap(short, long, default_value = "1.0")]
    delta: f64,

    /// Initial value
    #[clap(long, default_value = "0.0")]
    x0: f64,

    /// Number of samples to generate
    #[clap(short, long, default_value = "10")]
    n: usize,

    /// Random number generator seed
    ///
    /// If not provided, a random seed is provided by the system.
    #[clap(long)]
    seed: Option<u64>,

    /// Target distribution
    ///
    /// This is the distribution to sample.
    /// The function should be a valid mathematical expression
    #[clap(default_value = "exp(-1/2 x^2)")]
    f: String,
}

impl Args {
    fn parse_distribution(&self) -> anyhow::Result<impl FnMut(f64) -> anyhow::Result<f64>> {
        let mut d = parse_expression_x_to_1(&self.f)?;
        Ok(move |x: f64| -> anyhow::Result<f64> {
            let d = d(x)?;
            if d < 0.0 {
                anyhow::bail!("Expected a positive value, got: {}, maybe the provided function is not a distribution?", d);
            }
            Ok(d)
        })
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[derive(ValueEnum, Serialize)]
enum ProposalType {
    /// [x - delta, x + delta]
    Uniform,
    /// Gaussian(x, delta)
    Normal,
}

#[derive(Debug, Clone)]
#[derive(Serialize)]
struct Draw {
    x: f64,
    /// Number of accepted proposals so far
    acc: usize,
}