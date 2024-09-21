use std::{any::TypeId, rc::Rc};

use bytemuck::Pod;
use wgpu::{util::DeviceExt, Buffer, CommandEncoder};

use crate::{GpGpuGenericBuffer, GpGpuBuffer, GpGpuDevice};



impl<T: Pod> Clone for Storage<T> {
    fn clone(&self) -> Self {
        Self(self.0.clone(), std::marker::PhantomData)
    }
}

impl<T: Pod> GpGpuGenericBuffer for Storage<T> {
    fn buffer(&self) -> &Buffer {
        &self.0.buffer
    }

    fn device(&self) -> &GpGpuDevice {
        &self.0.device
    }

    fn shader_read_only(&self) -> bool {
        self.0.shader_read_only
    }
}
