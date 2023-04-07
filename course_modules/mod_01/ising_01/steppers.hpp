
#pragma once

#include "PottsNd.hpp"

#ifdef ISING_OPENCL
#include <CL/cl.hpp>
#endif // ISING_OPENCL

#include <nm4pLib/utils/math.hpp>

using lc::experimental::periodicIndex;

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

	template <class PottsModel>
	class GenericPottsNdMetropolisStepper
	{
	public:

		using Index = PottsModel::Index;

		GenericPottsNdMetropolisStepper(PottsModel& model) : m_model(model) { this->steps = model.spinCount(); };

		PottsModel& model() { return m_model; }
		const PottsModel& model() const { return m_model; }

		int steps = 0;

		void step(std::default_random_engine& engine) {

			auto& model = this->model();
			constexpr auto NDim = PottsModel::NDim();

			std::array<std::uniform_int_distribution<int>, NDim> index_distributions;
			std::uniform_real_distribution<double> d(0, 1);
			for (size_t i = 0; i < NDim; ++i)
				index_distributions[i] = std::uniform_int_distribution<int>(0, model.shape()[i]);

			// picks a random index in the lattice
			auto random_index = [&engine, &index_distributions]() -> Index {
				Index idx;
				for (size_t i = 0; i < NDim; ++i)
					idx[i] = index_distributions[i](engine);
				return idx;
			};

			// Periodic Boundary Conditions
			auto pbc = [&model](Index idx) -> Index {
				for (size_t i = 0; i < NDim; ++i)
					idx[i] = periodicIndex(idx[i], model.shape()[i]);
				return idx;
			};

			// returns true with probability `p`
			auto trueWithProbability = [&](double p) -> bool {
				return d(engine) < p;
			};

			// flips a spin in the lattice
			auto flipSpin = [&](const Index& idx) {
				model[idx] = !model[idx];
			};

			for (int t = 0; t < this->steps; ++t)
			{
				const auto index = random_index();
			}
		}

	private:

	private:
		PottsModel& m_model;
	};



}