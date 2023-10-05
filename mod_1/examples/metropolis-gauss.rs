
use mod_1::metropolis_1d::{MH1D, kernels::UniformKernel};
use nm4p_common::{clap, stat::mean_var};
use clap::Parser;
use rand::SeedableRng;

#[derive(Parser, Debug)]
struct Args {
    /// The number of generated samples
    n: usize,

    /// The seed for the random number generator
    /// Use `None` for a random seed
    #[clap(short, long)]
    seed: Option<u64>,

    /// The starting point
    #[clap(long, default_value = "0")]
    x0: f64,

    /// The center of the gaussian
    #[clap(long, default_value = "10")]
    mu: f64,

    /// The standard deviation of the gaussian
    #[clap(long, default_value = "1")]
    sigma: f64,

    /// The guesser step size
    #[clap(long, default_value = "1")]
    delta: f64,

    /// The number of samples to skip
    #[clap(long, default_value = "0")]
    skip: usize,

    /// The output plot file
    #[clap(long)]
    plot: Option<String>,

    /// Print the generated samples
    #[clap(long)]
    print: bool,

    /// The stride between printed samples
    #[clap(long, default_value = "1")]
    stride: usize,

    /// Print statistics about the generated samples
    #[clap(long)]
    print_stats: bool,
}

fn main() {
    let args = Args::parse();

    let mut rng = rand::rngs::StdRng::seed_from_u64(args.seed.unwrap_or(rand::random()));

    let metro = MH1D::new(
        |x: f64| (-((x - args.mu)).powi(2) / (2.0 * args.sigma.powi(2))).exp(),
        args.x0,
        UniformKernel::new(args.delta),
    );

    let start = std::time::Instant::now();
    let samples = metro
        .iter(&mut rng)
        .step_by(args.stride)
        .skip(args.skip)
        .take(args.n)
        .collect::<Vec<_>>();
    let elapsed = start.elapsed();

    if args.print {
        for (x, accepted) in &samples {
            println!("{} {}", x, *accepted as u8);
        }
    }

    if args.print_stats {
        let (mean, var) = mean_var(samples.iter().map(|(x, _)| *x));
        println!("Mean: {} vs {}", mean, args.mu);
        println!("Var: {} vs {}, sigma: {} vs {}", var, args.sigma.powi(2), var.sqrt(), args.sigma);
        let n_iter = (args.n + args.skip) * args.stride;
        println!("{:?}/it, {:.0} it/s", elapsed / n_iter as u32, n_iter as f64 / elapsed.as_micros() as f64 * 1e6);
    }

    if let Some(_) = &args.plot {
        plot(samples.iter().map(|(x, _)| *x).collect(), &args).unwrap();
    }
}

fn plot(points: Vec<f64>, args: &Args) -> Result<(), Box<dyn std::error::Error>> {
    use plotters::prelude::*;
    let path = args.plot.as_ref().unwrap().clone() + ".svg";
    let root = SVGBackend::new(&path, (1024 / 2, 768 / 2)).into_drawing_area();

    root.fill(&WHITE)?;

    let mut chart = ChartBuilder::on(&root)
        .margin(10)
        .caption(
            format!(
                "Metropolis for a Gaussian, mu = {}, sigma = {}, delta = {}",
                args.mu, args.sigma, args.delta
            ),
            ("sans-serif", 15),
        )
        .set_label_area_size(LabelAreaPosition::Left, 60)
        .set_label_area_size(LabelAreaPosition::Bottom, 40)
        .build_cartesian_2d(
            0.0..points.len() as f64,
            (args.x0).min(args.mu - 4.0 * args.sigma)..args.x0.max(args.mu + 4.0 * args.sigma),
        )?;

    chart
        .configure_mesh()
        .max_light_lines(4)
        .y_desc("y")
        .x_desc("sample")
        .draw()?;

    chart.draw_series(
        //points.iter().enumerate().map(|(i, y)| Cross::new((i as f64, *y), 3, BLACK.filled())),
        points.iter().enumerate().map(|(i, y)| Cross::new((i as f64, *y), 3, BLACK.filled())),
    )?;

    root.present().expect("Unable to write result to file, please make sure 'plotters-doc-data' dir exists under current dir");

    Ok(())
}