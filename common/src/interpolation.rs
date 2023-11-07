

use nalgebra as na;

use na::Matrix4;

/// A Polynomial of degree `N - 1`
#[derive(Debug, Clone, Copy)]
pub struct Polynomial<const N: usize, T = f64> {
    coefficients: [T; N],
}

impl<const N: usize, T> Polynomial<N, T> {
    pub fn new(coefficients: [T; N]) -> Self {
        Polynomial { coefficients }
    }

    pub fn eval<T2>(&self, x: T) -> T2
    where
        T: Clone,
        T: std::ops::Mul<T, Output = T>,
        T2: Clone,
        T2: num_traits::Zero + num_traits::One,
        T2: std::ops::Mul<T, Output = T2>,
        T2: std::ops::Add<T2, Output = T2>,
    {
        let mut x_i = T2::one();
        let mut y = T2::zero();
        for i in 0..N {
            y = y + x_i.clone() * self.coefficients[i].clone();
            x_i = x_i * x.clone();
        }
        y
    }
}

pub fn solve_quadratic(a: f64, b: f64, c: f64) -> Option<(f64, f64)> {
    if a == 0.0 {
        Some((-c / b, -c / b))
    } else {
        let discriminant = b * b - 4.0 * a * c;

        if discriminant < 0.0 {
            None
        } else {
            let x_0 = (-b - discriminant.sqrt()) / (2.0 * a);
            let x_1 = (-b + discriminant.sqrt()) / (2.0 * a);
            Some((x_0, x_1))
        }
    }
}

pub fn cubic_steady_points(
    cubic: Polynomial<4, f64>
) -> Option<(f64, f64)> {
    solve_quadratic(
        cubic.coefficients[3] * 3.0,
        cubic.coefficients[2] * 2.0,
        cubic.coefficients[1],
    )
}

pub fn interpolating_cubic(
    y_y_prime_0: (f64, f64),
    y_y_prime_1: (f64, f64),
) -> Polynomial<4, f64> {
    #[rustfmt::skip]
    const E_INV: Matrix4<f64> = Matrix4::new(
        1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        -3.0, 3.0, -2.0, -1.0,
        2.0, -2.0, 1.0, 1.0,
    );

    let (y_0, y_prime_0) = y_y_prime_0;
    let (y_1, y_prime_1) = y_y_prime_1;

    let coefficients = E_INV * na::Vector4::new(
        y_0,
        y_1,
        y_prime_0,
        y_prime_1
    );

    Polynomial::new(coefficients.data.0[0])
}