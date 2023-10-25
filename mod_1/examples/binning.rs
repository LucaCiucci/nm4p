use std::collections::BTreeMap;

use nm4p_common::{lerp, stat::{binning, var, mean_var, autocorr_int_inner, autocorr_fft, estimate_rough_tau_int}, indicatif, clap, rand_distr, rand};
use clap::Parser;
use rand::{SeedableRng, prelude::Distribution};

#[derive(Parser)]
struct Args {
    figure: String,

    #[clap(long)]
    tau: f64,

    #[clap(long)]
    comparison: bool,

    #[clap(short, long)]
    n: usize,

    #[clap(long)]
    repetitions: usize,

    #[clap(long)]
    k_max: usize,

    #[clap(long)]
    subdivisions: usize,
}

fn main() {
    let args = Args::parse();
    let mut rng = rand::rngs::StdRng::seed_from_u64(42);

    let tau_int = (-1.0 / args.tau).exp() / (1.0 - (-1.0 / args.tau).exp());

    let k = |i: usize| lerp(
        (1.0f64).ln(),
        (args.k_max as f64).ln(),
        i as f64 / args.subdivisions as f64
    ).exp().round() as usize;

    let bar = indicatif::ProgressBar::new(args.repetitions as u64);

    let mut tau_ints: BTreeMap<usize, Vec<f64>> = BTreeMap::new();
    let mut tau_ints_bc: BTreeMap<usize, Vec<f64>> = BTreeMap::new();
    let mut tau_ints_explicit_summation: BTreeMap<usize, Vec<f64>> = BTreeMap::new();
    let mut rough_tau_ints = Vec::new();
    for i in 0..args.repetitions {
        bar.inc(1);

        let samples = make_samples(args.tau, args.n, &mut rng);

        let (_mu, var_orig) = mean_var(samples.iter().cloned());
        let var_mu_orig = var_orig / samples.len() as f64;

        let rough_tau_int = estimate_rough_tau_int(&samples).unwrap();
        rough_tau_ints.push(rough_tau_int);

        let autocorr = autocorr_fft(&samples);
        let autocorr_int = autocorr_int_inner(autocorr.iter().cloned(), false).collect::<Vec<_>>(); // TODO maybe false??? see estimate_rough_tau_int_impl

        for i_k in 0..=args.subdivisions {
            let k = k(i_k);
            let (n_bins, binned) = binning(
                &samples,
                k,
            );
            let (n_bins_2, binned_2) = binning(
                &samples,
                k * 2,
            );
            let tau_int_2_p1 = (var(binned.into_iter()) / n_bins as f64) / var_mu_orig;
            let tau_int = (tau_int_2_p1 - 1.0) / 2.0;
            let tau_int_2_p1_bc = (var(binned_2.into_iter()) / n_bins_2 as f64) / var_mu_orig * 2.0 - tau_int_2_p1;
            let tau_int_bc = (tau_int_2_p1_bc - 1.0) / 2.0;
            tau_ints
                .entry(k)
                .or_insert_with(Vec::new)
                .push(tau_int);
            tau_ints_bc
                .entry(k * 2)
                .or_insert_with(Vec::new)
                .push(tau_int_bc);
            tau_ints_explicit_summation
                .entry(k)
                .or_insert_with(Vec::new)
                .insert(i, autocorr_int[k]);
        }
    }

    let tau_ints = tau_ints
        .into_iter()
        .map(|(k, sigma_mu)| {
            let (mean_sigma_mu, var_sigma_mu) = mean_var(sigma_mu.into_iter());
            (k, mean_sigma_mu, var_sigma_mu)
        })
        .collect::<Vec<_>>();
    let tau_ints_bc = tau_ints_bc
        .into_iter()
        .map(|(k, sigma_mu)| {
            let (mean_sigma_mu, var_sigma_mu) = mean_var(sigma_mu.into_iter());
            (k, mean_sigma_mu, var_sigma_mu)
        })
        .collect::<Vec<_>>();
    let tau_ints_explicit_summation = tau_ints_explicit_summation
        .into_iter()
        .map(|(k, sigma_mu)| {
            let (mean_sigma_mu, var_sigma_mu) = mean_var(sigma_mu.into_iter());
            (k, mean_sigma_mu, var_sigma_mu)
        })
        .collect::<Vec<_>>();

    let (rough_tau_int, var_rough_tau_int) = mean_var(rough_tau_ints.into_iter());

    plot(args.tau, tau_int, tau_ints, tau_ints_bc, tau_ints_explicit_summation, rough_tau_int, var_rough_tau_int, &args).unwrap();
}

fn make_samples(
    tau: f64,
    n: usize,
    rng: &mut impl rand::Rng,
) -> Vec<f64> {
    (0..n).map({
        let a = (-1.0 / tau).exp();
        let b = (1.0 - a.powi(2)).sqrt();
        let normal = rand_distr::Normal::new(0.0, 1.0).unwrap();
        let mut last = normal.sample(rng);
        move |_| {
            let y = normal.sample(rng);
            let x = a * last + b * y;
            last = x;
            x
        }
    }).collect()
}

fn plot(
    tau_exp: f64,
    tau_int: f64,
    tau_ints: Vec<(usize, f64, f64)>,
    tau_ints_bc: Vec<(usize, f64, f64)>,
    tau_ints_explicit_summation: Vec<(usize, f64, f64)>,
    rough_tau_int: f64,
    var_rough_tau_int: f64,
    args: &Args,
) -> Result<(), Box<dyn std::error::Error>> {
    use plotters::prelude::*;
    let path = format!("mod_1/img/plots/{}.svg", args.figure);
    let root = SVGBackend::new(&path, (1024 / 2, 768 / 2)).into_drawing_area();

    root.fill(&WHITE)?;

    let x_range = (1.0 / tau_exp)..(args.k_max as f64 / tau_exp);

    let mut chart = ChartBuilder::on(&root)
        .margin(10)
        .set_label_area_size(LabelAreaPosition::Left, 40)
        .set_label_area_size(LabelAreaPosition::Bottom, 40)
        .set_label_area_size(LabelAreaPosition::Top, 40)
        .build_cartesian_2d(
            x_range.clone().log_scale(),
            0.0..1.1,
        )?
        .set_secondary_coord(
            ((args.n as f64)..(args.n as f64 / args.k_max as f64)).log_scale(),
            0.0..1.1,
        );

    chart
        .configure_mesh()
        .max_light_lines(4)
        .y_desc("relative to tau_exp")
        .x_label_formatter(&|x: &f64| format!("{x:e}"))
        .axis_desc_style(("sans-serif", 20))
        .x_desc("k / tau_int")
        .draw()?;

    chart
        .configure_secondary_axes()
        .x_desc("N / k")
        .x_label_formatter(&|x: &f64| format!("{x:e}"))
        .axis_desc_style(("sans-serif", 20))
        .draw()?;

    chart.draw_series(
        LineSeries::new(
            [
                (x_range.start, 1.0),
                (x_range.end, 1.0),
            ],
            BLACK.stroke_width(1),
        )
    )?
        .label("tau_exp")
        .legend(|(x, y)| PathElement::new(vec![(x, y), (x + 20, y)], BLACK));
    chart.draw_series(
        LineSeries::new(
            [
                (x_range.start, tau_int / tau_exp),
                (x_range.end, tau_int / tau_exp),
            ],
            RED.stroke_width(2),
        )
    )?
        .label("tau_int")
        .legend(|(x, y)| PathElement::new(vec![(x, y), (x + 20, y)], RED));

    if args.comparison {
        // rough tau_int
        chart.draw_series(
            LineSeries::new(
                [
                    (x_range.start, rough_tau_int / tau_exp),
                    (x_range.end, rough_tau_int / tau_exp),
                ],
                GREEN.stroke_width(1),
            )
        )?
            .label("tau_int (rough)")
            .legend(|(x, y)| PathElement::new(vec![(x, y), (x + 20, y)], GREEN));
        chart.draw_series(
            std::iter::once(Polygon::new(
                [
                    (x_range.end, (rough_tau_int + var_rough_tau_int.sqrt()) / tau_exp),
                    (x_range.start, (rough_tau_int + var_rough_tau_int.sqrt()) / tau_exp),
                    (x_range.start, (rough_tau_int - var_rough_tau_int.sqrt()) / tau_exp),
                    (x_range.end, (rough_tau_int - var_rough_tau_int.sqrt()) / tau_exp)
                ],
                &GREEN.mix(0.2),
            ))
        )?;
    }

    let mut draw_tau_series = |
        name: &str,
        tau_ints_explicit_summation: &[(usize, f64, f64)],
        color: RGBColor,
    | {
        chart.draw_series(
            std::iter::once(Polygon::new(
                tau_ints_explicit_summation
                    .iter()
                    .rev()
                    .map(|(k, tau, var_tau)| (*k as f64 / tau_exp, (*tau + var_tau.sqrt()) / tau_exp))
                    .chain(
                        tau_ints_explicit_summation
                            .iter()
                            .map(|(k, tau, var_tau)| (*k as f64 / tau_exp, (*tau - var_tau.sqrt()) / tau_exp))
                    )
                    .collect::<Vec<_>>(),
                &color.mix(0.2),
            ))
        ).unwrap();
    
        chart.draw_series(
            tau_ints_explicit_summation.iter().map(|(k, sigma, var_sigma)| ErrorBar::new_vertical(
                *k as f64 / tau_exp,
                (*sigma - var_sigma.sqrt()) / tau_exp,
                (*sigma) / tau_exp,
                (*sigma + var_sigma.sqrt()) / tau_exp,
                color.filled(),
                5
            ))
        ).unwrap();
    
        chart.draw_series(LineSeries::new(
            tau_ints_explicit_summation.iter().map(|(k, sigma, _var_sigma)| (*k as f64 / tau_exp, *sigma / tau_exp)),
            &color,
        )).unwrap()
            .label(name)
            .legend(move |(x, y)| ErrorBar::new_vertical(x + 10, y - 5, y, y + 5, color.filled(), 5));
    };

    if args.comparison {
        draw_tau_series("explicit c_k summation", &tau_ints_explicit_summation, RED);
        draw_tau_series("binning (bias corrected)", &tau_ints_bc, BLUE);
    }
    draw_tau_series("binning", &tau_ints, BLACK);

    chart
        .configure_series_labels()
        .position(SeriesLabelPosition::LowerRight)
        .background_style(&WHITE)
        .border_style(&BLACK)
        .draw()?;

    root.present().expect("Unable to write result to file, please make sure 'plotters-doc-data' dir exists under current dir");

    Ok(())
}
