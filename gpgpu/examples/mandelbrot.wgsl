
@group(0)
@binding(0)
var<storage, read_write> image_buffer: array<f32>;

// the size of the image
@group(0)
@binding(1)
var<uniform> shape: vec2<u32>;


@compute @workgroup_size(8)
fn main(
    @builtin(global_invocation_id) id: vec3<u32>,
) {
    // maps the global_id to a complex number
    let c = vec2(
        f32(id.x) / f32(shape.x) - 0.7,
        (f32(id.y) / f32(shape.y) - 0.5) * f32(shape.y) / f32(shape.x)
    );

    // write the result of the mandelbrot function to the image buffer
    image_buffer[id.x + id.y * shape.x] = mandelbrot(c * 3.0);
}

// ================================
//       Mandelbrot function
// ================================
// Simplified version of https://www.shadertoy.com/view/4df3Rn (by Inigo Quilez)

const B: f32 = 256.0;

fn mandelbrot(c: vec2<f32>) -> f32 {
    var l: f32 = 0.0;
    var z = vec2(0.0);
    for (var i = 0; i < 512; i++) {
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        if dot(z, z) > B * B {
            break;
        }
        l += 1.0;
    }

    if l > 511.0 {
        return 0.0;
    }

    let sl = l - log2(log2(dot(z, z))) + 4.0;

    let al = smoothstep(-0.1, 0.0, sin(0.5 * 6.2831 * 0.0));
    l = mix(l, sl, al);

    return l;
}