
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
    numbers[index] = numbers[index] + offset;
}