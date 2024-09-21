use std::{any::{Any, TypeId}, rc::Rc};

use bytemuck::Pod;
use futures::channel::oneshot;
use wgpu::{util::DeviceExt, Buffer, CommandEncoder};

use crate::{GpGpuDevice, PodData};

pub struct GpGpuBuffer<T: ?Sized>(pub(crate) Rc<GpGpuBufferInner>, std::marker::PhantomData<T>, GpGpuDevice);

impl<T: ?Sized> Clone for GpGpuBuffer<T> {
    fn clone(&self) -> Self {
        GpGpuBuffer(Rc::clone(&self.0), std::marker::PhantomData, self.2.clone())
    }
}

impl<T: PodData + ?Sized> GpGpuBuffer<T> {
    pub fn cast_to_generic(&self) -> GpGpuBuffer<dyn Any> {
        GpGpuBuffer(Rc::clone(&self.0), std::marker::PhantomData, self.2.clone())
    }

    pub fn stage(&self, encoder: &mut CommandEncoder) {
        if let Some(staging_buffer) = &self.0.staging_buffer {
            encoder.copy_buffer_to_buffer(
                &self.0.buffer,
                0,
                staging_buffer,
                0,
                self.0.buffer.size(),
            );
        }
    }

    pub fn write(&self, value: &T) {
        if !self.0.write {
            panic!("The buffer is not writable");
        }

        // copilot:
        //let buffer = self.0.buffer.slice(..);
        //let mut data = buffer.get_mapped_range_mut();
        //data.copy_from_slice(bytemuck::cast_slice(&std::slice::from_ref(value)));
        //drop(data);
        // https://sotrh.github.io/learn-wgpu/beginner/tutorial6-uniforms/#a-controller-for-our-camera :
        self.0.device.0.queue.write_buffer(&self.0.buffer, 0, PodData::bytes(value));
    }

    pub fn shader_read_only(&self) -> bool {
        self.0.shader_read_only
    }
}

impl<T: Pod> GpGpuBuffer<[T]> {
    pub async fn read(&self) -> Vec<T> where T: Sized {
        let staging_buffer = self.0.staging_buffer.as_ref().expect("The buffer is not readable");
        let buffer_slice = staging_buffer.slice(..);

        let (sender, receiver) = oneshot::channel();
        buffer_slice.map_async(wgpu::MapMode::Read, move |a| {
            sender.send(a).unwrap();
        });
        receiver.await.expect("Failed to await the channel").expect("Failed to map the buffer");

        let data = buffer_slice.get_mapped_range();
        let result = bytemuck::cast_slice(&data).to_vec();
        drop(data);
        staging_buffer.unmap();

        result
    }
}

impl GpGpuBuffer<dyn Any> {
    pub fn downcast<T: PodData>(&self) -> Result<GpGpuBuffer<T>, BufferDowncastError> {
        if self.0.ty == TypeId::of::<T>() {
            Ok(GpGpuBuffer(Rc::clone(&self.0), std::marker::PhantomData, self.2.clone()))
        } else {
            Err(BufferDowncastError {
                requested: TypeId::of::<T>(),
                found: self.0.ty,
            })
        }
    }
}

impl<T: PodData + ?Sized> From<GpGpuBuffer<T>> for GpGpuBuffer<dyn Any> {
    fn from(buffer: GpGpuBuffer<T>) -> Self {
        buffer.cast_to_generic()
    }
}

pub(crate) struct GpGpuBufferInner {
    device: GpGpuDevice,
    pub(crate) buffer: Buffer,
    pub(crate) binding_type:wgpu::BufferBindingType,
    staging_buffer: Option<Buffer>,
    shader_read_only: bool,
    write: bool,
    ty: TypeId,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct BufferDowncastError {
    pub requested: TypeId,
    pub found: TypeId,
}

impl std::fmt::Display for BufferDowncastError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "BufferDowncastError: requested {:?}, found {:?}", self.requested, self.found)
    }
}

impl std::error::Error for BufferDowncastError {}

#[must_use]
pub struct UniformBuilder<'a, T: PodData + ?Sized> {
    device: &'a GpGpuDevice,
    label: Option<String>,
    value: &'a T,
}

impl<'a, T: PodData + ?Sized> UniformBuilder<'a, T> {
    pub fn new(device: &'a GpGpuDevice, value: &'a T) -> Self {
        Self {
            device,
            label: None,
            value,
        }
    }

    pub fn label(self, label: impl Into<String>) -> Self {
        Self {
            label: Some(label.into()),
            ..self
        }
    }

    pub fn build(self) -> GpGpuBuffer<T> {
        let buffer = self.device.0.device.create_buffer_init(
            &wgpu::util::BufferInitDescriptor {
                label: self.label.as_deref(),
                contents: PodData::bytes(self.value), // TODO maybe use `bytemuck::cast_ref` instead
                usage: wgpu::BufferUsages::UNIFORM,
            }
        );

        GpGpuBuffer(Rc::new(GpGpuBufferInner {
            device: self.device.clone(),
            buffer,
            binding_type: wgpu::BufferBindingType::Uniform,
            staging_buffer: None,
            shader_read_only: true,
            write: true,
            ty: TypeId::of::<T>(),
        }), std::marker::PhantomData, self.device.clone())
    }
}

#[must_use]
pub struct StorageBuilder<'a, T: ?Sized> {
    device: &'a GpGpuDevice,
    label: Option<String>,
    value: &'a T,

    // the buffer can be updated to the GPU
    write: bool,
    // the buffer can be read from the GPU
    read: bool,
    // the buffer can be read from the compute shader
    shader_read_only: bool,
}

impl<'a, T: PodData + ?Sized> StorageBuilder<'a, T> {
    pub fn new(device: &'a GpGpuDevice, value: &'a T) -> StorageBuilder<'a, T> {
        StorageBuilder {
            device,
            label: None,
            value,
            write: true,
            read: true,
            shader_read_only: false,
        }
    }

    pub fn label(self, label: impl Into<String>) -> Self {
        Self {
            label: Some(label.into()),
            ..self
        }
    }

    pub fn write(self, write: bool) -> Self {
        Self {
            write,
            ..self
        }
    }

    pub fn read(self, read: bool) -> Self {
        Self {
            read,
            ..self
        }
    }

    pub fn build(self) -> GpGpuBuffer<T> {
        let mut usage = wgpu::BufferUsages::STORAGE;
        if self.write {
            usage |= wgpu::BufferUsages::COPY_DST;
        }
        if self.read {
            usage |= wgpu::BufferUsages::COPY_SRC;
        }

        let buffer = self.device.0.device.create_buffer_init(
            &wgpu::util::BufferInitDescriptor {
                label: self.label.as_deref(),
                contents: PodData::bytes(self.value),
                usage,
            }
        );

        let staging_buffer: Option<Buffer> = if self.read {
            let label = self.label.as_ref().map(|l| format!("{}-readback", l));

            // the readback buffer
            let staging_buffer = self.device.0.device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
                label: label.as_deref(),
                contents: PodData::bytes(self.value), // TODO it is useless to copy the data here
                usage: wgpu::BufferUsages::MAP_READ | wgpu::BufferUsages::COPY_DST,
            });

            Some(staging_buffer)
        } else {
            None
        };

        GpGpuBuffer(
            Rc::new(GpGpuBufferInner {
                device: self.device.clone(),
                buffer,
                binding_type: wgpu::BufferBindingType::Storage { read_only: self.shader_read_only },
                staging_buffer,
                shader_read_only: self.shader_read_only,
                write: self.write,
                ty: TypeId::of::<T>(),
            }),
            std::marker::PhantomData,
            self.device.clone(),
        )
    }
}