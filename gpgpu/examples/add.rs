use nm4p_gpgpu::{GpGpu, GpGpuDevice};
use pollster::FutureExt;

fn main() {
    let device = GpGpuDevice::acquire().block_on().unwrap();

    // create buffers
    let init = (0..10).map(|i| i as f32).collect::<Vec<_>>();
    let numbers = device.storage(&init[..]).build();
    let offset = device.uniform(&42f32).label("Ciao").build();

    let mut adder = GpGpu::builder(&device)
        .add(0, numbers.clone())
        .add(1, offset)
        .build(include_str!("add.wgsl"));

    device.encode(|encoder| {
        adder.run(encoder, 1, (init.len() as u32, 1, 1));
        numbers.stage(encoder);
    });

    let r = device.poll_while(numbers.read()).block_on();
    println!("{:?}", &r[..5]);
}