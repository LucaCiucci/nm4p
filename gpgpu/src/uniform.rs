use std::{any::TypeId, rc::Rc};

use bytemuck::Pod;
use wgpu::{util::DeviceExt, Buffer};

use crate::{GpGpuGenericBuffer, GpGpuBuffer, GpGpuDevice};

struct UniformInner {
    device: GpGpuDevice,
    pub(crate) buffer: Buffer,
    label: Option<String>,
    ty: TypeId,
}

pub struct Uniform<T: Pod>(pub(crate) Rc<UniformInner>, std::marker::PhantomData<T>);

impl<T: Pod> Clone for Uniform<T> {
    fn clone(&self) -> Self {
        Self(self.0.clone(), std::marker::PhantomData)
    }
}

impl<T: Pod> GpGpuGenericBuffer for Uniform<T> {
    fn buffer(&self) -> &Buffer {
        &self.0.buffer
    }

    fn device(&self) -> &GpGpuDevice {
        &self.0.device
    }

    fn stage(&self, _encoder: &mut wgpu::CommandEncoder) {
    }

    fn shader_read_only(&self) -> bool {
        true
    }
}

impl<T: Pod> GpGpuBuffer<T> for Uniform<T> {
}