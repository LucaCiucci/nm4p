
use mod_1::metropolis_1d::{MH1D, kernels::UniformKernel};
use nm4p_common::{lerp, indicatif, stat::estimate_rough_tau_int, rand};
use rand::SeedableRng;

fn main() {

    let mut tau_vs_acceptances: Vec<(f64, f64)> = Vec::new();

    let n_mc_iter = 1000000;
    let n_subdivisions = 200;
    let delta_range = 0.1..=10000.0f64;

    
    let bar = indicatif::ProgressBar::new(n_subdivisions);

    for i in 1..=n_subdivisions {
        let mut rng = rand::rngs::StdRng::seed_from_u64(42);
        bar.inc(1);

        let delta = lerp(
            delta_range.start().ln(),
            delta_range.end().ln(),
            i as f64 / n_subdivisions as f64
        ).exp();

        let (samples, acceptance) = {
            let metro = MH1D::new(
                |x: f64| (-(x).powi(2) / (2.0)).exp(),
                0.0,
                UniformKernel::new(delta),
            );

            let mut accepted = 0;
            let samples = metro
                .iter(&mut rng)
                .take(n_mc_iter)
                .map(|(x, acc)| {
                    accepted += acc as usize;
                    x
                })
                .collect::<Vec<_>>();
            (samples, accepted as f64 / n_mc_iter as f64)
        };

        let tau_int = estimate_rough_tau_int(&samples).unwrap_or(0.0);

        tau_vs_acceptances.push((acceptance, tau_int));
    }

    plot(&tau_vs_acceptances).unwrap();
}

fn plot(tau_vs_acceptances: &Vec<(f64, f64)>) -> Result<(), Box<dyn std::error::Error>> {
    use plotters::prelude::*;
    let path = "mod_1/img/plots/metrogauss-tau_vs_acc.svg";
    let root = SVGBackend::new(&path, (1024 / 2, 768 / 2)).into_drawing_area();

    root.fill(&WHITE)?;

    let mut chart = ChartBuilder::on(&root)
        .margin(10)
        .caption(
            format!("tau_int vs acceptance for a Gaussian"),
            ("sans-serif", 15),
        )
        .set_label_area_size(LabelAreaPosition::Left, 60)
        .set_label_area_size(LabelAreaPosition::Bottom, 40)
        .build_cartesian_2d(
            //(tau_vs_acceptances[0].0..tau_vs_acceptances.last().unwrap().0).log_scale(),
            tau_vs_acceptances.last().unwrap().0..tau_vs_acceptances[0].0,
            (1.0..1000.0).log_scale(),
        )?;

    chart
        .configure_mesh()
        .max_light_lines(4)
        .y_desc("tau_int")
        .x_desc("acceptance")
        .draw()?;

    chart.draw_series(
        //points.iter().enumerate().map(|(i, y)| Cross::new((i as f64, *y), 3, BLACK.filled())),
        tau_vs_acceptances.iter().filter(|(_, tau_int)| *tau_int > 0.0).map(|(acceptance, tau_int)| Cross::new((*acceptance, *tau_int), 3, BLACK.filled())),
    )?;

    root.present().expect("Unable to write result to file, please make sure 'plotters-doc-data' dir exists under current dir");

    Ok(())
}