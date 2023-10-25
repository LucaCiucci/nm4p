
use mod_1::metropolis_1d::{MH1D, kernels::UniformKernel};
use nm4p_common::{stat::{estimate_rough_tau_int_impl, mean_var, RoughTauIntEstimationMethod::*}, indicatif::{self, ProgressStyle}, lerp};
use rand::SeedableRng;

fn main() {
    let n_subdivisions = 20;
    let iter_range = 100..=10_000_000usize;

    let repetitions = 1_000;

    let mut tau_int_and_var_vs_iters: Vec<(usize, f64, f64)> = Vec::new();
    let mut tau_int_and_var_vs_iters_d: Vec<(usize, f64, f64)> = Vec::new();

    let iter = |i: u64| lerp(
        (*iter_range.start() as f64).ln(),
        (*iter_range.end() as f64).ln(),
        i as f64 / n_subdivisions as f64
    ).exp().round() as usize;

    let style = ProgressStyle::with_template("{elapsed} {wide_bar} iters: {pos}/{len} {percent}% eta: {eta_precise}").unwrap();
    let total: usize = (0..=n_subdivisions).map(|i| iter(i)).sum();
    let bar = indicatif::ProgressBar::new(total as u64 * repetitions * 2).with_style(style);

    let mut rng = rand::rngs::StdRng::seed_from_u64(42);

    for i in 0..=n_subdivisions {
        let iter = iter(i);

        let (tau_int, tau_int_var) = mean_var((0..repetitions).filter_map(|_| {
            bar.inc(iter as u64);

            let metro = MH1D::new(
                |x: f64| (-(x).powi(2) / 2.0).exp(),
                0.0,
                UniformKernel::new(1.0),
            );
            let chain = metro.iter(&mut rng);

            let samples = chain
                .map(|(x, _)| x)
                .take(iter)
                .collect::<Vec<_>>();

            estimate_rough_tau_int_impl(
                &samples,
                Normal,
            ).map(|(_m, tau_int)| tau_int)
        }));

        tau_int_and_var_vs_iters.push((iter, tau_int, tau_int_var));

        let (tau_int, tau_int_var) = mean_var((0..repetitions).filter_map(|_| {
            bar.inc(iter as u64);

            let metro = MH1D::new(
                |x: f64| (-(x).powi(2) / 2.0).exp(),
                0.0,
                UniformKernel::new(1.0),
            );
            let chain = metro.iter(&mut rng);

            let samples = chain
                .map(|(x, _)| x)
                .take(iter)
                .collect::<Vec<_>>();

            estimate_rough_tau_int_impl(
                &samples,
                Derivative,
            ).map(|(_m, tau_int)| tau_int)
        }));

        tau_int_and_var_vs_iters_d.push((iter, tau_int, tau_int_var));
    }

    plot(tau_int_and_var_vs_iters, tau_int_and_var_vs_iters_d).unwrap();
}

fn plot(tau_int_and_var_vs_iters: Vec<(usize, f64, f64)>, tau_int_and_var_vs_iters_d: Vec<(usize, f64, f64)>) -> Result<(), Box<dyn std::error::Error>> {
    use plotters::prelude::*;
    let path = "mod_1/img/plots/autocorr-int-finder-tau_int-vs-iter.svg";
    let root = SVGBackend::new(&path, (1024 / 2, 768 / 2)).into_drawing_area();

    root.fill(&WHITE)?;

    let min = tau_int_and_var_vs_iters[0].0;
    let max = tau_int_and_var_vs_iters.last().unwrap().0;

    let mut chart = ChartBuilder::on(&root)
        .margin(10)
        .caption(
            format!(
                "tau_int vs chain len"
            ),
            ("sans-serif", 15),
        )
        .set_label_area_size(LabelAreaPosition::Left, 60)
        .set_label_area_size(LabelAreaPosition::Bottom, 40)
        .build_cartesian_2d(
            (min as f64..max as f64).log_scale(),
            0.0..40.0,
        )?;

    chart
        .configure_mesh()
        .max_light_lines(4)
        .y_desc("tau_int")
        .x_desc("chain len (metropolis iterations)")
        .draw()?;

    chart.draw_series(
        std::iter::once(Polygon::new(
            tau_int_and_var_vs_iters
                .iter()
                .rev()
                .map(|(iter, tau_int, tau_int_var)| (*iter as f64, *tau_int + tau_int_var.sqrt() / 2.0))
                .chain(
                    tau_int_and_var_vs_iters
                        .iter()
                        .map(|(iter, tau_int, tau_int_var)| (*iter as f64, *tau_int - tau_int_var.sqrt() / 2.0))
                )
                .collect::<Vec<_>>(),
            &BLACK.mix(0.2),
        ))
    )?;

    chart.draw_series(
        tau_int_and_var_vs_iters.iter().map(|(iter, tau_int, tau_int_var)| ErrorBar::new_vertical(*iter as f64, *tau_int - tau_int_var.sqrt() / 2.0, *tau_int, *tau_int + tau_int_var.sqrt() / 2.0, BLACK.filled(), 5))
    )?
        .label("c_M < 0")
        .legend(|(x, y)| ErrorBar::new_vertical(x, y - 5, y, y + 5, BLACK.filled(), 5));

    chart.draw_series(LineSeries::new(
        tau_int_and_var_vs_iters.iter().map(|(iter, tau_int, _tau_int_var)| (*iter as f64, *tau_int)),
        &BLACK,
    ))?;

    chart.draw_series(
        std::iter::once(Polygon::new(
            tau_int_and_var_vs_iters_d
                .iter()
                .rev()
                .map(|(iter, tau_int, tau_int_var)| (*iter as f64, *tau_int + tau_int_var.sqrt() / 2.0))
                .chain(
                    tau_int_and_var_vs_iters_d
                        .iter()
                        .map(|(iter, tau_int, tau_int_var)| (*iter as f64, *tau_int - tau_int_var.sqrt() / 2.0))
                )
                .collect::<Vec<_>>(),
            &RED.mix(0.2),
        ))
    )?;

    chart.draw_series(
        tau_int_and_var_vs_iters_d.iter().map(|(iter, tau_int, tau_int_var)| ErrorBar::new_vertical(*iter as f64, *tau_int - tau_int_var.sqrt() / 2.0, *tau_int, *tau_int + tau_int_var.sqrt() / 2.0, RED.filled(), 5))
    )?
        .label("c_M < c_(M + 1)")
        .legend(|(x, y)| ErrorBar::new_vertical(x, y - 5, y, y + 5, RED.filled(), 5));

    chart.draw_series(LineSeries::new(
        tau_int_and_var_vs_iters_d.iter().map(|(iter, tau_int, _tau_int_var)| (*iter as f64, *tau_int)),
        &RED,
    ))?;

    chart
        .configure_series_labels()
        .position(SeriesLabelPosition::LowerRight)
        .background_style(&WHITE)
        .border_style(&BLACK)
        .draw()?;

    root.present().expect("Unable to write result to file, please make sure 'plotters-doc-data' dir exists under current dir");

    Ok(())
}