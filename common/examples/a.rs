use nm4p_common::interpolation::interpolating_cubic;



fn main() {
    let y_y_prime_0 = (0.0, 1.0);
    let y_y_prime_1 = (0.0, -1.0);
    let cubic = interpolating_cubic(
        y_y_prime_0,
        y_y_prime_1
    );
    println!("{:?}", cubic);
    let y: f64 = cubic.eval(0.5);
    println!("{}", y);
}