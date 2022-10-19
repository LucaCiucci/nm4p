
#pragma once

#include "PottsNd.hpp"

#ifdef ISING_OPENCL
#include <CL/cl.hpp>
#endif // ISING_OPENCL

namespace nm4p
{
	using std::string;
	using namespace std::string_literals;

	class Ising2dStepper
	{
	public:

		Ising2dStepper(Ising2d& model) : m_model(model) {}

		virtual ~Ising2dStepper() = default;

		Ising2d& model() { return m_model; }
		const Ising2d& model() const { return m_model; }

		double beta() const { return m_beta; };
		void setBeta(double beta) { m_beta = beta; };

		virtual void step(std::default_random_engine& engine) = 0;

	private:
		Ising2d& m_model;
		double m_beta = 0.1;
	};

	class SimpleMetropolisIsingStepper final : public Ising2dStepper
	{
	public:

		SimpleMetropolisIsingStepper(Ising2d& model) : Ising2dStepper(model), steps(model.N()* model.N()) {};

		~SimpleMetropolisIsingStepper() override = default;

		int steps = 0;

		void step(std::default_random_engine& engine) override;
	};

#ifdef ISING_OPENCL
	class OpenCLIsingStepper final : public Ising2dStepper
	{
	public:

		OpenCLIsingStepper(Ising2d& model, cl::Context& context, const cl::Device& device);

		~OpenCLIsingStepper() override = default;

		int repetitions = 10;

		void step(std::default_random_engine& engine) override;

	private:

		using make_kernel = cl::make_kernel<cl::Buffer, cl::Buffer, unsigned, unsigned, float, int>;

		void update_random_seeds(std::default_random_engine& engine);

		make_kernel kernel();
		string readFile2String(const string& fileName);

		void step_impl(int repetitions, std::default_random_engine& engine);

	private:
		cl::Context m_context;
		cl::Device m_device;
		cl::CommandQueue m_queue;

		std::unique_ptr<cl::Buffer> m_gpu_lattice;
		std::unique_ptr<cl::Buffer> m_rand_seeds;

		std::unique_ptr<make_kernel> m_metro_step_kernel;
		string m_kernelProgramPath = ":/opencl/a.ocl";

		static inline constexpr size_t m_N_seeds = 32;
	};
#endif // ISING_OPENCL
}