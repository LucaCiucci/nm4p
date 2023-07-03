use nm4p_utils::stat::var;

fn main() {
    println!("Hello, world!");

    let v: Vec<f64> = vec![1.0, 2.0, 3.0, 4.0, 5.0];

    let a: f64 = var(v.iter().cloned());

    println!("variance: {}", a);
}