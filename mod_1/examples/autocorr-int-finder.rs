
use mod_1::metropolis_1d::{MH1D, kernels::UniformKernel};
use nm4p_common::{stat::{autocorr_int, autocorr_fft, estimate_rough_tau_int_impl}, clap};
use rand::SeedableRng;

use clap::Parser;

#[derive(Parser, Debug)]
struct Args {
    /// The number of generated samples
    n: usize,

    /// The maximum k for the autocorrelation
    max_k: usize,

    /// Whether to use corrected sum
    #[clap(long)]
    corrected: bool,

    /// The output plot file
    plot: String,

    #[clap(long)]
    on_derivative: bool,
}

fn main() {
    let args = Args::parse();

    let mut rng = rand::rngs::StdRng::seed_from_u64(42);

    let metro = MH1D::new(
        |x: f64| (-(x).powi(2) / 2.0).exp(),
        0.0,
        UniformKernel::new(1.0),
    );

    let samples = metro
        .iter(&mut rng)
        .map(|(x, _)| x)
        .take(args.n)
        .collect::<Vec<_>>();

    let autocorr = autocorr_fft(&samples)
        .into_iter()
        .take(args.max_k)
        .collect::<Vec<_>>();

    let autocorr_int = autocorr_int(&samples, args.corrected)
        .take(args.max_k)
        .collect::<Vec<_>>();

    #[allow(non_snake_case)]
    let (M, tau_int) = estimate_rough_tau_int_impl(
        &samples,
        args.on_derivative,
        10,
    ).unwrap();
    println!("M: {}, tau_int = {}", M, tau_int);

    plot(autocorr, M as f64, &args).unwrap();
    plot_int(autocorr_int, M as f64, &args).unwrap();
}

fn plot(corr: Vec<f64>, cut: f64, args: &Args) -> Result<(), Box<dyn std::error::Error>> {
    use plotters::prelude::*;
    let path = args.plot.clone() + ".svg";
    let root = SVGBackend::new(&path, (1024 / 2, 768 / 2)).into_drawing_area();

    root.fill(&WHITE)?;

    let min = *corr.iter().min_by(|x, y| x.partial_cmp(y).unwrap()).unwrap();
    let max = *corr.iter().max_by(|x, y| x.partial_cmp(y).unwrap()).unwrap();

    let mut chart = ChartBuilder::on(&root)
        .margin(10)
        .caption(
            format!(
                "autocorrelation"
            ),
            ("sans-serif", 15),
        )
        .set_label_area_size(LabelAreaPosition::Left, 60)
        .set_label_area_size(LabelAreaPosition::Bottom, 40)
        .build_cartesian_2d(
            0.0..corr.len() as f64,
            min..max,
        )?;

    chart
        .configure_mesh()
        .max_light_lines(4)
        .y_desc("autocorrelation")
        .x_desc("k")
        .draw()?;

    chart.draw_series(
        //points.iter().enumerate().map(|(i, y)| Cross::new((i as f64, *y), 3, BLACK.filled())),
        corr.iter().enumerate().map(|(i, y)| Cross::new((i as f64, *y), 3, BLACK.filled())),
    )?;

    chart.draw_series(
        LineSeries::new(
            std::iter::once((cut, min)).chain(std::iter::once((cut, max))),
            RED.stroke_width(4),
        )
    )?;

    root.present().expect("Unable to write result to file, please make sure 'plotters-doc-data' dir exists under current dir");

    Ok(())
}

fn plot_int(corr: Vec<f64>, cut: f64, args: &Args) -> Result<(), Box<dyn std::error::Error>> {
    use plotters::prelude::*;
    let path = args.plot.clone() + "-int.svg";
    let root = SVGBackend::new(&path, (1024 / 2, 768 / 2)).into_drawing_area();

    root.fill(&WHITE)?;

    let min = *corr.iter().min_by(|x, y| x.partial_cmp(y).unwrap()).unwrap();
    let max = *corr.iter().max_by(|x, y| x.partial_cmp(y).unwrap()).unwrap();

    let mut chart = ChartBuilder::on(&root)
        .margin(10)
        .caption(
            format!(
                "integrated autocorrelation"
            ),
            ("sans-serif", 15),
        )
        .set_label_area_size(LabelAreaPosition::Left, 60)
        .set_label_area_size(LabelAreaPosition::Bottom, 40)
        .build_cartesian_2d(
            0.0..corr.len() as f64,
            min..max,
        )?;

    chart
        .configure_mesh()
        .max_light_lines(4)
        .y_desc("integrated autocorrelation vs M")
        .x_desc("M")
        .draw()?;

    chart.draw_series(
        LineSeries::new(
            std::iter::once((cut, min)).chain(std::iter::once((cut, max))),
            RED.stroke_width(4),
        )
    )?;

    chart.draw_series(
        //points.iter().enumerate().map(|(i, y)| Cross::new((i as f64, *y), 3, BLACK.filled())),
        corr.iter().enumerate().map(|(i, y)| Cross::new((i as f64, *y), 3, BLACK.filled())),
    )?;

    root.present().expect("Unable to write result to file, please make sure 'plotters-doc-data' dir exists under current dir");

    Ok(())
}