use codici_mod_0::congruent_generator::CongruentGenerator;

fn main() {
    let mut rng = CongruentGenerator::default();

    let name = rng.params().name().unwrap_or("custom");
    println!("Running with {:#?} ({})", rng.params(), name);

    for i in 0..10 {
        println!("{i:3} -> {:.4}", rng.generate());
    }
}