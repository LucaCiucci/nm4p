use std::path::Path;

use nm4p_gpgpu::{GpGpu, GpGpuDevice};
use pollster::FutureExt;

fn main() {
    let device = GpGpuDevice::acquire().block_on().unwrap();

    let w = 800;
    let h = 600;

    let image_buffer = device.storage(&vec![0f32; w * h][..]).build();
    let shape_buffer = device.uniform(&[w as u32, h as u32]).build();

    let mut mandelbrot = GpGpu::builder(&device)
        .add(0, image_buffer.clone())
        .add(1, shape_buffer)
        .build(include_str!("mandelbrot.wgsl"));

    let start = std::time::Instant::now();
    device.encode(|encoder| {
        mandelbrot.run(encoder, 1, (w as u32, h as u32, 1));
        image_buffer.stage(encoder);
    });

    let values = device.poll_while(image_buffer.read()).block_on();
    println!("Time: {:?}", start.elapsed());

    let color_map = |l: f32| -> [u8; 4] {
        let f = |add: f32| (0.5 + 0.5 * (3.0 + l * 0.15 + add).cos()).clamp(0.0, 1.0) * 255.0;
        [f(0.0) as u8, f(0.6) as u8, f(1.0) as u8, 255]
    };

    let pixels = values.into_iter().map(color_map).flatten().collect::<Vec<_>>();

    let image = image::RgbaImage::from_vec(w as _, h as _, pixels).unwrap();

    image.save(Path::new(env!("CARGO_MANIFEST_DIR")).join("docs/mandelbrot.png")).unwrap();
}