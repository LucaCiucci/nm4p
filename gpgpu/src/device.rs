use std::{cell::RefCell, future::Future, rc::{Rc, Weak}};

use futures::lock::Mutex;
use wgpu::{AdapterInfo, Device, Queue, RequestDeviceError};

use crate::{buffer::{StorageBuilder, UniformBuilder}, PodData};


pub(crate) struct GpGpuDeviceInner {
    pub device_info: AdapterInfo,
    pub device: Device,
    pub queue: Queue,
}

/// GPGPU device
///
/// Everything happens on a [`wgpu::Device`] and a [`wgpu::Queue`], this struct
/// a smart wrapper around them that makes it easier to work with them by reusing
/// the same device and queue across multiple calls.
///
///
#[derive(Clone)]
pub struct GpGpuDevice(pub(crate) Rc<GpGpuDeviceInner>);

impl GpGpuDevice {
    /// Get the current device or create a new one if it doesn't exist
    pub async fn acquire() -> Result<Self, RequestDeviceError> { // TODO allow to select the adapter in the future
        // see https://forum.dfinity.org/t/how-do-you-guys-make-async-call-inside-thread-local/18960

        thread_local! {
            static DEVICE: RefCell<Weak<GpGpuDeviceInner>> = RefCell::new(Weak::new()); // TODO use Cell
            static CREATION_LOCK: Rc<Mutex<()>> = Rc::new(Mutex::new(())); // TODO mutex is an overkill since we're in a thread-local context
        }

        let Some(current) = DEVICE.with(|device| device.borrow_mut().upgrade()) else {
            let m = CREATION_LOCK.with(|lock| lock.clone());
            let _lock = m.lock().await;

            if let Some(current) = DEVICE.with(|device| device.borrow_mut().upgrade()) {
                return Ok(Self(current));
            }

            let new_instance = Rc::new(Self::init_async().await?);

            DEVICE.with(|device| {
                *device.borrow_mut() = Rc::downgrade(&new_instance);
            });

            return Ok(Self(new_instance));
        };

        Ok(Self(current))
    }

    async fn init_async() -> Result<GpGpuDeviceInner, RequestDeviceError> {
        let instance = wgpu::Instance::new(wgpu::InstanceDescriptor::default());
        //let adapters = instance.enumerate_adapters(Default::default()).into_iter().map(|a| a.get_info()).collect::<Vec<_>>();
        //println!("{:#?}", adapters);
        let adapter = instance
            .request_adapter(&wgpu::RequestAdapterOptions {
                power_preference: wgpu::PowerPreference::HighPerformance,
                force_fallback_adapter: false,
                compatible_surface: None,
            })
            .await
            .expect("Failed to find an appropriate adapter");
    
    
        adapter
            .request_device(
                &wgpu::DeviceDescriptor::default(),
                None,
            ).await
            .map(|(device, queue)| {
                GpGpuDeviceInner { device_info: adapter.get_info(), device, queue }
            })
    }

    pub fn adapter_info(&self) -> &AdapterInfo {
        &self.0.device_info
    }

    pub fn encode(&self, f: impl FnOnce(&mut wgpu::CommandEncoder)) {
        let mut encoder = self.0.device.create_command_encoder(&wgpu::CommandEncoderDescriptor {
            label: None,
        });
        f(&mut encoder);
        let _index = self.0.queue.submit(std::iter::once(encoder.finish()));
        // note, the index could be used to poll the device and wait for the commands to finish.
        // We ignore this because on WebGPU this has no effect and this behavior might be confusing.
    }

    /// Exposes the [`wgpu::Device::poll`] method
    pub fn poll(&self, maintain: wgpu::Maintain) -> wgpu::MaintainResult {
        self.0.device.poll(maintain)
    }

    /// [Poll](Self::poll) the device while some task is running
    ///
    /// Some operations such as [`GpGpu::read_buffer`] require polling the device,
    /// this method allows you to run a task continuously polling the device until
    /// the task is done. This is useful if you don't have a control loop that polls
    /// the device (like a game loop).
    ///
    /// # Example
    /// ```ignore
    /// let r = gpgpu.poll_while(async {
    ///     let r = gpgpu.read_buffer::<f32>("numbers").await.unwrap();
    ///     dbg!(r.len());
    /// });
    pub async fn poll_while<T>(&self, task: impl Future<Output = T>) -> T {
        futures::pin_mut!(task);
        loop {
            self.poll(wgpu::Maintain::Poll);
            if let std::task::Poll::Ready(result) = futures::poll!(&mut task) {
                break result;
            }
        }
    }

    /// Create a new uniform buffer
    pub fn uniform<'a, T: PodData + ?Sized>(&'a self, value: &'a T) -> UniformBuilder<'a, T> {
        UniformBuilder::new(self, value)
    }

    /// Create a new storage buffer
    pub fn storage<'a, T: PodData + ?Sized>(&'a self, value: &'a T) -> StorageBuilder<'a, T> {
        StorageBuilder::new(self, value)
    }
}