// From: https://en.wikipedia.org/wiki/Linear_congruential_generator#Parameters_in_common_use
// glibc constants:
const a: u32 = 1103515245;
const c: u32 = 12345;

fn gpgpu_mini_rand(seed: u32) -> u32 {
    return a * seed + c;
}