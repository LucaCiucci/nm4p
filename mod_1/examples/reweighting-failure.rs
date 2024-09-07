
use nm4p_common::{
    rand::{self, SeedableRng},
    rand_distr::{self, Distribution}, stat::mean_var,
};

const N: usize = 2000;
const RANGE: f64 = 6.0;
const N_DIV: usize = 50;

fn main() {
    let mut rng = rand::rngs::StdRng::seed_from_u64(41);

    let normal = rand_distr::Normal::new(0.0, 1.0).unwrap();

    let samples: Vec<f64> = (0..N)
        .map(|_| normal.sample(&mut rng))
        .collect();

    let gaussian = |x: f64, mu: f64| (-(x - mu).powi(2)/2.0).exp();

    let data: Vec<(f64, f64, f64)> = (0..)
        .map(|i| i as f64 / N_DIV as f64 * RANGE)
        .take_while(|mu| *mu <= RANGE)
        .map(|mu| {
            let z: Vec<f64> = samples
                .iter()
                .cloned()
                // REWEIGHTING HERE:
                .map(|x| x * gaussian(x, mu) / gaussian(x, 0.0))
                .collect();
            let (mean, var) = mean_var(z);
            (mu, mean, var / N as f64)
        })
        .collect();

    plot(&data);
}

fn plot(data: &[(f64, f64, f64)]) {
    use plotters::prelude::*;
    let path = "mod_1/img/plots/reweighting-failure.svg";

    let root = SVGBackend::new(&path, (1024 / 2, 768 / 2)).into_drawing_area();

    root.fill(&WHITE).unwrap();

    let mut chart = ChartBuilder::on(&root)
        .margin(10)
        .set_label_area_size(LabelAreaPosition::Left, 40)
        .set_label_area_size(LabelAreaPosition::Bottom, 40)
        .build_cartesian_2d(
            0.0..RANGE,
            0.0..RANGE
        ).unwrap();

    chart
        .configure_mesh()
        //.max_light_lines(4)
        .disable_mesh()
        .y_desc("[sigma]")
        //.x_label_formatter(&|x: &f64| format!("{x:e}"))
        .axis_desc_style(("sans-serif", 20))
        .x_desc("mu [sigma]")
        .draw().unwrap();

    chart
        .draw_series(LineSeries::new(
            [
                (0.0, 0.0),
                (RANGE, RANGE),
            ],
            BLACK.stroke_width(2),
        )).unwrap()
        .label("exact")
        .legend(|(x, y)| PathElement::new(vec![(x, y), (x + 20, y)], BLACK));

    chart
        .draw_series(
            data
                .iter()
                .cloned()
                .map(|(mu, mean, var)| {
                    ErrorBar::new_vertical(
                        mu,
                        mean - var.sqrt(),
                        mean,
                        mean + var.sqrt(),
                        BLUE,
                        5,
                    )
                }),
        )
        .unwrap()
        .label("reweighted")
        .legend(|(x, y)| ErrorBar::new_vertical(x + 10, y - 5, y, y + 5, BLUE, 5));

    chart
        .configure_series_labels()
        .position(SeriesLabelPosition::UpperLeft)
        .background_style(&WHITE)
        .border_style(&BLACK)
        .draw()
        .unwrap();

    root.present().expect("Unable to write result to file, please make sure 'plotters-doc-data' dir exists under current dir");
}