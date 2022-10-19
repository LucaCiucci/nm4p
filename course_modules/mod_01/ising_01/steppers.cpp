
#include "steppers.hpp"

#include <QFile>

#undef max

#include "NeighborsIterator.hpp"

namespace nm4p
{

	void SimpleMetropolisIsingStepper::step(std::default_random_engine& engine)
	{
		auto& model = this->model();

		using Index = Ising2d::Index;

		// distributions
		std::uniform_int_distribution<int> di(0, model.N() - 1);
		std::uniform_int_distribution<int> dj(0, model.M() - 1);
		std::uniform_real_distribution<double> d(0, 1);

		// picks a random index in the lattice
		auto random_index = [&di, &dj, &engine]() -> Index {
			return { (size_t)di(engine), (size_t)dj(engine) };
		};

		// Periodic Boundary Conditions
		auto pbc = [&model](int i, int j) -> Index {
			return { (size_t)(i % model.N()), (size_t)(j % model.M()) };
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
			const auto& [i, j] = index;

			const auto spin = model[index] ? 1 : -1;

			double neighbour_sum = 0;
			for (auto [idx, v] : SimpleIsingField())
				// TODO with coupling
				// !!! with coupling
				neighbour_sum += (model[pbc(int(i) + idx[0], int(j) + idx[1])] ? 1 : -1) * v;

			const bool flip = trueWithProbability(exp(-2 * beta() * neighbour_sum * spin));

			if (flip)
				flipSpin(index);
		}
	}

#ifdef ISING_OPENCL

	OpenCLIsingStepper::OpenCLIsingStepper(Ising2d& model, cl::Context& context, const cl::Device& device) :
		Ising2dStepper(model),
		m_context(context),
		m_device(device),
		m_queue(context, device)
	{
		// create opncl buffers
		m_gpu_lattice.reset(new cl::Buffer(context, CL_MEM_READ_WRITE, sizeof(uint8_t) * (model.N() * model.M() + 7) / 8));
		m_rand_seeds.reset(new cl::Buffer(context, CL_MEM_READ_ONLY, sizeof(unsigned) * m_N_seeds));
	}

	void OpenCLIsingStepper::step(std::default_random_engine& engine)
	{
		this->step_impl(this->repetitions, engine);
	}

	void OpenCLIsingStepper::update_random_seeds(std::default_random_engine& engine)
	{
		std::uniform_int_distribution<unsigned> d(0, std::numeric_limits<unsigned>::max());
		std::vector<unsigned> seeds(m_N_seeds);
		for (auto& s : seeds)
			s = d(engine);
		m_queue.enqueueWriteBuffer(*m_rand_seeds, CL_TRUE, 0, seeds.size() * sizeof(unsigned), (void*)seeds.data());
		m_queue.flush();
	}

	OpenCLIsingStepper::make_kernel OpenCLIsingStepper::kernel()
	{
		if (m_metro_step_kernel)
			return *m_metro_step_kernel;

		string kernel_code = this->readFile2String(m_kernelProgramPath);
		cl::Program::Sources sources;
		sources.push_back({ kernel_code.c_str(),kernel_code.length() });
		cl::Program program(m_context, sources);
		if (program.build({ m_device }) != CL_SUCCESS) {
			string error = "Error building: "s + program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(m_device);
			throw std::runtime_error(error);
		}

		make_kernel metro_step(cl::Kernel(program, "metro_step"));
		
		// if it is a resource, we cache it, otherwise we will rebuild it everytime
		// so that it cna be changed live from file (slower)
		// TOOD cached option
		if (m_kernelProgramPath.starts_with(":"))
			m_metro_step_kernel.reset(new make_kernel(metro_step));

		return metro_step;
	}

	string OpenCLIsingStepper::readFile2String(const string& fileName)
	{
		QFile file(QString::fromStdString(fileName));
		file.open(QIODevice::ReadOnly | QIODevice::Text);
		QString s = file.readAll();
		return s.toStdString();
		//QDirIterator it(":", QDirIterator::Subdirectories);
		//while (it.hasNext()) {
		//	qDebug() << it.next();
		//}
	}

	void OpenCLIsingStepper::step_impl(int repetitions, std::default_random_engine& engine)
	{
		cl::NDRange global((model().N() * model().M() + 7) / 8);

		make_kernel metro_step_kernel = kernel();

		// populate buffer
		m_queue.enqueueWriteBuffer(*m_gpu_lattice, CL_TRUE, 0, (model().N() * model().M() + 7) / 8, (void*)model().rawData());

		for (int i = 0; i < repetitions; ++i)
		{
			this->update_random_seeds(engine);
			metro_step_kernel(cl::EnqueueArgs(m_queue, global), *m_gpu_lattice, *m_rand_seeds, model().N(), model().M(), this->beta(), 0).wait();
			this->update_random_seeds(engine);
			metro_step_kernel(cl::EnqueueArgs(m_queue, global), *m_gpu_lattice, *m_rand_seeds, model().N(), model().M(), this->beta(), 1).wait();
		}

		// pull buffer
		m_queue.enqueueReadBuffer(*m_gpu_lattice, CL_TRUE, 0, (model().N() * model().M() + 7) / 8, (void*)model().rawData());
	}

#endif // ISING_OPENCL
}