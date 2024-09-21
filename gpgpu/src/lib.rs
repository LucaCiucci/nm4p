use std::{any::Any, collections::HashMap};

use bytemuck::Pod;
use wgpu::{BindGroupLayoutDescriptor, CommandEncoder};

pub mod ext {
    pub use bytemuck;
    pub use wgpu;
}

mod device; pub use device::GpGpuDevice;
mod buffer; pub use buffer::GpGpuBuffer;

pub trait GpGpuValueBuffer<T> {
    fn copy(&self, value: &T);
}

pub trait PodData: 'static {
    fn bytes(value: &Self) -> &[u8];
}

impl<T: Pod> PodData for T {
    fn bytes(value: &Self) -> &[u8] {
        bytemuck::cast_slice(std::slice::from_ref(value)) // TODO maybe cast_ref
    }
}

impl<T: Pod> PodData for [T] {
    fn bytes(value: &Self) -> &[u8] {
        bytemuck::cast_slice(value)
    }
}

#[derive(Debug, Clone)]
pub struct Labeled<T> {
    binding: T,
    label: Option<String>,
}

impl<T> Labeled<T> {
    /// Get the binding number
    pub fn binding(&self) -> &T {
        &self.binding
    }

    /// Get the label, if any
    pub fn label(&self) -> Option<&str> {
        self.label.as_deref()
    }
}

impl<T: PartialEq> PartialEq for Labeled<T> {
    fn eq(&self, other: &Self) -> bool {
        self.binding == other.binding
    }
}

impl<T: Eq> Eq for Labeled<T> {}

impl<T: PartialOrd> PartialOrd for Labeled<T> {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        self.binding.partial_cmp(&other.binding)
    }
}

impl<T: Ord> Ord for Labeled<T> {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.binding.cmp(&other.binding)
    }
}

impl<T: std::hash::Hash> std::hash::Hash for Labeled<T> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.binding.hash(state);
    }
}

impl<T> From<T> for Labeled<T> {
    fn from(value: T) -> Self {
        Self {
            binding: value,
            label: None,
        }
    }
}

impl<T, S: ToString> From<(T, S)> for Labeled<T> {
    fn from(value: (T, S)) -> Self {
        Self {
            binding: value.0,
            label: Some(value.1.to_string()),
        }
    }
}

pub struct GpGpuBuilder {
    device: GpGpuDevice,
    buffers: HashMap<u32, GpGpuBuffer<dyn Any>>,
}

impl GpGpuBuilder {
    pub fn new(device: GpGpuDevice) -> Self {
        Self {
            device,
            buffers: HashMap::new(),
        }
    }

    pub fn add(
        mut self,
        binding: u32,
        buffer: impl Into<GpGpuBuffer<dyn Any>>,
    ) -> Self {
        self.buffers.insert(binding, buffer.into());
        self
    }

    pub fn build(
        self,
        source: &str,
    ) -> GpGpu {
        let module = self.device.0.device.create_shader_module(
            wgpu::ShaderModuleDescriptor {
                label: None,
                source: wgpu::ShaderSource::Wgsl(source.into()),
            }
        );

        let entries = self
            .buffers
            .iter()
            .map(|(binding, buf)| {
                wgpu::BindGroupLayoutEntry {
                    binding: *binding,
                    visibility: wgpu::ShaderStages::COMPUTE,
                    ty: wgpu::BindingType::Buffer {
                        //ty: wgpu::BufferBindingType::Storage { read_only: false },
                        ty: buf.0.binding_type,
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                }
            })
            .collect::<Vec<_>>();

        let device = &self.device;
        let compute_bind_group_layout = device.0.device.create_bind_group_layout(&BindGroupLayoutDescriptor {
            label: None,
            entries: &entries,
        });

        let entries = self
            .buffers
            .iter()
            .map(|(binding, buf)| {
                wgpu::BindGroupEntry {
                    binding: *binding,
                    resource: wgpu::BindingResource::Buffer(wgpu::BufferBinding {
                        buffer: &buf.0.buffer,
                        offset: 0,
                        size: None,
                    }),
                }
            })
            .collect::<Vec<_>>();

        let compute_bind_group = device.0.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: None,
            layout: &compute_bind_group_layout,
            entries: &entries,
        });

        let compute_pipeline_layout = device.0.device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("compute pipeline layout"),
            bind_group_layouts: &[&compute_bind_group_layout],
            push_constant_ranges: &[],
        });

        let compute_pipeline = device.0.device.create_compute_pipeline(&wgpu::ComputePipelineDescriptor {
            label: Some("compute pipeline"),
            layout: Some(&compute_pipeline_layout),
            module: &module,
            entry_point: "main",
            compilation_options: Default::default(),
            cache: None,
        });

        GpGpu {
            _device: self.device,
            _buffers: self.buffers.into_iter().map(|(_, buff)| buff).collect(),
            compute_bind_group,
            compute_pipeline,
        }
    }
}

pub struct GpGpu {
    _device: GpGpuDevice,
    _buffers: Vec<GpGpuBuffer<dyn Any>>,
    compute_bind_group: wgpu::BindGroup,
    compute_pipeline: wgpu::ComputePipeline,
}

impl GpGpu {
    pub fn builder(device: &GpGpuDevice) -> GpGpuBuilder {
        GpGpuBuilder::new(device.clone())
    }

    pub fn run(
        &mut self,
        encoder: &mut CommandEncoder,
        repetitions: usize,
        (x, y, z): (u32, u32, u32),
    ) {
        let mut compute_pass = encoder.begin_compute_pass(&wgpu::ComputePassDescriptor {
            label: None,
            timestamp_writes: None,
        });

        compute_pass.set_pipeline(&self.compute_pipeline);
        compute_pass.set_bind_group(0, &self.compute_bind_group, &[]);

        for _ in 0..repetitions {
            compute_pass.dispatch_workgroups(x, y, z);
        }
    }
}