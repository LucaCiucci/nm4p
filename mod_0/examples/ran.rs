use mod_0::ran::*;

fn main() {
    //let mut ran = Ran1::default();
    let mut ran = make_ran0();

    for _ in 0..20 {
        println!("{}", ran.generate());
    }
}
