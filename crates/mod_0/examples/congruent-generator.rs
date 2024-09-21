use mod_0::congruent_generator::CongruentGenerator;

fn main() {
    let mut rng = CongruentGenerator::default();

    let name = rng.params().name().unwrap_or("custom");
    eprintln!("Running with {:#?} ({})", rng.params(), name);

    for _ in 0..10 {
        println!("{:.6}", rng.generate());
    }
}
