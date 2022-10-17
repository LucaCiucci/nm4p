

#include <iostream>

#include "opencl_utils.hpp"

#ifdef ISING_OPENCL

namespace nm4p
{
	std::pair<std::unique_ptr<cl::Context>, std::vector<cl::Device>> init_CL_context()
	{

		// https://ulhpc-tutorials.readthedocs.io/en/latest/gpu/opencl/

		std::vector<cl::Platform> all_platforms;
		cl::Platform::get(&all_platforms);

		std::cout << "Platforms: " << std::endl;
		for (const auto& platform : all_platforms)
			std::cout << " - " << platform.getInfo<CL_PLATFORM_NAME>() << std::endl;

		cl::Platform default_platform = all_platforms[0];
		std::cout << "Using platform: " << default_platform.getInfo<CL_PLATFORM_NAME>() << "\n";

		std::vector<cl::Device> all_devices;
		default_platform.getDevices(CL_DEVICE_TYPE_ALL, &all_devices);
		if (all_devices.size() == 0) {
			std::cout << " No devices found.\n";
			exit(1);
		}

		cl::Device default_device = all_devices[0];
		std::cout << "Using device: " << default_device.getInfo<CL_DEVICE_NAME>() << "\n";

		std::vector<cl::Device> devices = { default_device };

		return { std::make_unique<cl::Context>(devices), devices };
	}
}

#endif // ISING_OPENCL