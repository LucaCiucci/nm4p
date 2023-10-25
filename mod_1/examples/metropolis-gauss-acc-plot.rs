
use mod_1::metropolis_1d::{MH1D, kernels::UniformKernel};
use nm4p_common::{lerp, indicatif, rand};
use rand::SeedableRng;

fn main() {

    let mut acceptances: Vec<(f64, f64)> = Vec::new();

    let n_mc_iter = 10000000;
    let n_subdivisions = 100;
    let delta_range = 0.001..=10000.0f64;

    
    let bar = indicatif::ProgressBar::new(n_subdivisions);

    for i in 1..=n_subdivisions {
        let mut rng = rand::rngs::StdRng::seed_from_u64(42);
        bar.inc(1);

        let delta = lerp(
            delta_range.start().ln(),
            delta_range.end().ln(),
            i as f64 / n_subdivisions as f64
        ).exp();

        let metro = MH1D::new(
            |x: f64| (-(x).powi(2) / (2.0)).exp(),
            0.0,
            UniformKernel::new(delta),
        );

        let accepted = metro
            .iter(&mut rng)
            .take(n_mc_iter)
            .filter(|(_, accepted)| *accepted)
            .count() as f64 / n_mc_iter as f64;

        acceptances.push((delta, accepted));
    }

    plot(&acceptances).unwrap();
    plot_log(&acceptances).unwrap();
}

fn plot(acceptances: &Vec<(f64, f64)>) -> Result<(), Box<dyn std::error::Error>> {
    use plotters::prelude::*;
    let path = "mod_1/img/plots/metrogauss-acceptance.svg";
    let root = SVGBackend::new(&path, (1024 / 2, 768 / 2)).into_drawing_area();

    root.fill(&WHITE)?;

    let mut chart = ChartBuilder::on(&root)
        .margin(10)
        .caption(
            format!("Acceptance vs delta for a Gaussian"),
            ("sans-serif", 15),
        )
        .set_label_area_size(LabelAreaPosition::Left, 60)
        .set_label_area_size(LabelAreaPosition::Bottom, 40)
        .build_cartesian_2d(
            (acceptances[0].0..acceptances.last().unwrap().0).log_scale(),
            0.0..1.0,
        )?;

    chart
        .configure_mesh()
        .max_light_lines(4)
        .y_desc("acceptance")
        .x_desc("delta")
        .draw()?;

    chart.draw_series(
        //points.iter().enumerate().map(|(i, y)| Cross::new((i as f64, *y), 3, BLACK.filled())),
        acceptances.iter().map(|(delta, acc)| Cross::new((*delta, *acc), 3, BLACK.filled())),
    )?;

    root.present().expect("Unable to write result to file, please make sure 'plotters-doc-data' dir exists under current dir");

    Ok(())
}

fn plot_log(acceptances: &Vec<(f64, f64)>) -> Result<(), Box<dyn std::error::Error>> {
    use plotters::prelude::*;
    let path = "mod_1/img/plots/metrogauss-acceptance-log.svg";
    let root = SVGBackend::new(&path, (1024 / 2, 768 / 2)).into_drawing_area();

    root.fill(&WHITE)?;

    let mut chart = ChartBuilder::on(&root)
        .margin(10)
        .caption(
            format!("Acceptance vs delta for a Gaussian"),
            ("sans-serif", 15),
        )
        .set_label_area_size(LabelAreaPosition::Left, 60)
        .set_label_area_size(LabelAreaPosition::Bottom, 40)
        .build_cartesian_2d(
            (acceptances[0].0..acceptances.last().unwrap().0).log_scale(),
            (0.0..1.0).log_scale(),
        )?;

    chart
        .configure_mesh()
        .max_light_lines(4)
        .y_desc("acceptance")
        .x_desc("delta")
        .draw()?;

    chart.draw_series(
        //points.iter().enumerate().map(|(i, y)| Cross::new((i as f64, *y), 3, BLACK.filled())),
        acceptances.iter().map(|(delta, acc)| Cross::new((*delta, *acc), 3, BLACK.filled())),
    )?;

    root.present().expect("Unable to write result to file, please make sure 'plotters-doc-data' dir exists under current dir");

    Ok(())
}