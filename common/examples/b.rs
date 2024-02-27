

use differential::Differential;

//#[derive(Debug, Clone, Default)]
//struct OptionalDiff(Option<Box<GenericDiff>>);
//
//type GenericDiff = Differential<f64, OptionalDiff>;
//
//impl OptionalDiff {
//    fn new()
//}
//
//impl std::ops::Add for OptionalDiff {
//    type Output = Self;
//    fn add(self, rhs: Self) -> Self::Output {
//        OptionalDiff(
//            if let (
//                Some(lhs),
//                Some(rhs)
//            ) = (self.0, rhs.0) {
//                Some(Box::new(*lhs + *rhs))
//            } else {
//                None
//            }
//        )
//    }
//}

type DD = Differential<f64, Differential<>>;

fn main() {
    println!("Hello, world!");

    let x = DD::new(
        1.0,
        Differential::new(
            1.0,
            1.0
        )
    );

    let y = x * x;
    //let y = num_traits::real::Real::powi(x, 2);

    println!("{:?}", y);
}