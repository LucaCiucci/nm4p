
@group(0)
@binding(0)
var<storage, read_write> numbers: array<f32>;

// uniform offset
@group(0)
@binding(1)
var<uniform> offset: f32;

@compute @workgroup_size(8)
fn main(
    @builtin(global_invocation_id) global_id: vec3<u32>,
) {
    let index = global_id.x;

    var value = index + u32(offset);
    for (var i = 0; i < 100; i = i + 1) {
        value = gpgpu_mini_rand(value);
    }

    numbers[index] = f32(value);
}

const a: u32 = 1103515245;
const c: u32 = 12345;

fn gpgpu_mini_rand(seed: u32) -> u32 {
    return a * seed + c;
}