
#pragma once

#include <memory>

#ifdef ISING_OPENCL
//#define CL_USE_DEPRECATED_OPENCL_2_0_APIS
#include <CL/cl.hpp>

namespace nm4p
{

	std::pair<std::unique_ptr<cl::Context>, std::vector<cl::Device>> init_CL_context();
}

#endif