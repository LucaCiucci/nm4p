
#include <iostream>

#include <chrono>

#include <QMainWindow>
#include <QApplication>

#include <qgraphicsview.h>

//using namespace std;
using namespace std::chrono_literals;

#include "Potts2dItem.hpp"

//#include <gnuplotpp/gnuplotpp.hpp>

#include "PottsNd.hpp"
#include "NeighborsIterator.hpp"
#include <nm4pLib/utils/strings.hpp>

#include "opencl_utils.hpp"

#include <random>

using namespace nm4p;

#undef max

void step(Ising2d& ising, size_t steps, double beta, std::default_random_engine& engine)
{
	//std::random_device dev;
	std::uniform_int_distribution<int> di(0, ising.N() - 1);
	std::uniform_int_distribution<int> dj(0, ising.M() - 1);
	std::uniform_real_distribution<double> d(0, 1);

	SimpleIsingField field;

	//constexpr double beta = 1.4;


	if (false && ising.N() * ising.M() > lc::experimental::sqr(500))
	{
		std::vector<std::thread> threads;
		auto nThreads = std::thread::hardware_concurrency();

		for (int t = 0; t < nThreads; ++t)
		{
			threads.emplace_back([&, t]() {
				for (int i = (t * ising.N()) / nThreads; i < ((t + 1) * ising.N()) / nThreads; ++i)
					for (int j = 0; j < ising.M(); ++j)
					{
						double s = 0;
						for (auto [idx, v] : field)
						{
							size_t ii = (i + idx[0]) % ising.N();
							size_t jj = (j + idx[1]) % ising.M();

							s += v * (ising[{ii, jj}] ? 1.0 : -1.0);
						}

						auto p = exp(-s * 2 * beta * (ising[{ (size_t)i, (size_t)j }] ? 1.0 : -1.0));
						//int exponent = (int)(-s * (ising[{ (size_t)i, (size_t)j }] ? 1.0 : -1.0));
						//auto p = exp_table[exponent + 4];

						bool flip = d(engine) < p;

						if (flip)
							ising.at({ (size_t)i, (size_t)j }) = !ising.at({ (size_t)i, (size_t)j });
					}
				});
		}

		for (auto& t : threads)
			t.join();
	}

	if (false)
	for (int i = 0; i < ising.N(); ++i)
		for (int j = 0; j < ising.M(); ++j)
		{
			double s = 0;
			for (auto [idx, v] : field)
			{
				size_t ii = (i + idx[0]) % ising.N();
				size_t jj = (j + idx[1]) % ising.M();

				s += v * (ising[{ii, jj}] ? 1.0 : -1.0);
			}

			auto p = exp(-s * 2 * beta * (ising[{ (size_t)i, (size_t)j }] ? 1.0 : -1.0));
			//int exponent = (int)(-s * (ising[{ (size_t)i, (size_t)j }] ? 1.0 : -1.0));
			//auto p = exp_table[exponent + 4];

			bool flip = d(engine) < p;

			if (flip)
				ising.at({ (size_t)i, (size_t)j }) = !ising.at({ (size_t)i, (size_t)j });
		}

	if (false)
	return;

	for (size_t t = 0; t < steps; ++t)
	{
		int i = di(engine);
		int j = dj(engine);

		double s = 0;
		for (auto [idx, v] : field)
		{
			size_t ii = (i + idx[0]) % ising.N();
			size_t jj = (j + idx[1]) % ising.M();

			s += v * (ising[{ii, jj}] ? 1.0 : -1.0);
		}

		auto p = exp(-s * 2 * beta * (ising[{ (size_t)i, (size_t)j }] ? 1.0 : -1.0));
		//int exponent = (int)(-s * (ising[{ (size_t)i, (size_t)j }] ? 1.0 : -1.0));
		//auto p = exp_table[exponent + 4];

		bool flip = d(engine) < p;

		if (flip)
			ising.at({ (size_t)i, (size_t)j }) = !ising.at({ (size_t)i, (size_t)j });
	}
}

void GPU_step(Ising2d& ising, size_t steps, double beta, cl::Context& context, const cl::Device& device, std::default_random_engine& engine)
{
	cl::Buffer gpu_lattice(context, CL_MEM_READ_WRITE, sizeof(uint8_t) * (ising.N() * ising.M() + 7) / 8*0+100000000);
	constexpr size_t N_seeds = 32;
	cl::Buffer rand_seeds(context, CL_MEM_READ_ONLY, sizeof(unsigned) * N_seeds);

	cl::CommandQueue queue(context, device);

	std::vector<uint8_t> data;
	int counter = 0;
	uint8_t byte = 0;
	size_t pushedBytes = 0;
	auto flush = [&]() {
		if (data.empty())
			return;

		queue.enqueueWriteBuffer(gpu_lattice, CL_TRUE, pushedBytes, data.size(), (void*)data.data());
		queue.flush();// !!!
		//queue.finish();
		pushedBytes += data.size();
		data.clear();
	};
	auto pushBool = [&](bool value) {
		//auto v = (int)value;
		//auto bit = (int)value >> counter++;
		byte |= (int)value << counter++;
		if (counter >= 8)
		{
			data.push_back(byte);
			byte = 0;
			counter = 0;
		}

		if (data.size() > 10000*100)
			flush();
	};

	for (int i = 0; i < ising.N(); ++i)
		for (int j = 0; j < ising.M(); ++j)
			pushBool(ising[{ (size_t)i, (size_t)j }]);
	flush();

	auto update_random_seeds = [&]() {
		//std::default_random_engine en;
		std::uniform_int_distribution<unsigned> d(0, std::numeric_limits<unsigned>::max());
		std::vector<unsigned> seeds(N_seeds);
		for (auto& s : seeds)
			s = d(engine);
		queue.enqueueWriteBuffer(rand_seeds, CL_TRUE, 0, seeds.size() * sizeof(unsigned), (void*)seeds.data());
		queue.flush();
	};
	update_random_seeds();

	using a = cl_uint8;
	std::string kernel_code = R"wqnifp(

//typedef unsigned int uint32;
//#define UINT32_MAX UINT_MAX

// https://en.wikipedia.org/wiki/Xorshift
typedef struct _xorshift32_state {
	unsigned a;
} xorshift32_state;

/* The state word must be initialized to non-zero */
unsigned xorshift32(xorshift32_state *state)
{
	/* Algorithm "xor" from p. 4 of Marsaglia, "Xorshift RNGs" */
	unsigned x = state->a;
	x ^= x << 13;
	x ^= x >> 17;
	x ^= x << 5;
	return state->a = x;
}

float rand_real(float min, float max, xorshift32_state* state)
{
	return min + (max - min) * (float)xorshift32(state) / (float)UINT_MAX;
}

bool getSpin(int i, int j, global const unsigned char* lattice, size_t N, size_t M)
{
	i = i % N;
	j = j % M;
	const size_t index = i * M + j;
	const size_t char_index = index / 8;
	const size_t bit_index = index % 8;
	return (lattice[char_index] >> bit_index) & 1;
}

void setSpin(size_t i, size_t j, bool spin, global unsigned char* lattice, size_t N, size_t M)
{
	const size_t index = i * M + j;
	const size_t char_index = index / 8;
	const size_t bit_index = index % 8;
	if (spin)
		lattice[char_index] |= 1 << bit_index;
	else
		lattice[char_index] &= ~(1 << bit_index);
}

void kernel metro_step(global unsigned char* lattice, global const unsigned* rand_seeds, unsigned N, unsigned M, const float beta, int parity)
{
	size_t id = get_global_id(0);

	// init rand seed
	xorshift32_state state;

	// set the random seed based on the global id
	// we use id*id because id seems to be a bit too regular
	// TODO: use a better seed
	state.a = id;
	for (int i = 0; i < 32; ++i)
		if (id & (1 << i))
			state.a ^= rand_seeds[i];
	//for (int i = 0; i < 10; ++i)
	//	xorshift32(&state);

	//lattice[get_global_id(0)] = (unsigned char)(rand_real(0, 1) < 0.5f) ? 0u : 1u;


	//for (int parity = 0; parity < 2; ++parity)
	{
		for (size_t k = 0; k < 8; ++k)
		{
			const size_t pt_index = id * 8 + k;
			const size_t i = pt_index / M;
			const size_t j = pt_index % M;

			if (i >= N || j >= M)
				continue;

			if ((i + j) % 2 != parity || false)
				continue;

			const bool spin_bool = getSpin(i, j, lattice, N, M);
			const int spin = spin_bool ? 1 : -1;

			int neighbors = 0;
			neighbors += getSpin(i - 1, j, lattice, N, M) ? 1 : -1;
			neighbors += getSpin(i + 1, j, lattice, N, M) ? 1 : -1;
			neighbors += getSpin(i, j - 1, lattice, N, M) ? 1 : -1;
			neighbors += getSpin(i, j + 1, lattice, N, M) ? 1 : -1;

			const float p = exp(-2.f * beta * spin * neighbors);

			if (rand_real(0, 1, &state) < p)
				setSpin(i, j, !spin_bool, lattice, N, M);

			//for (int i = 0; i < 32; ++i)
			//	xorshift32(&state);

			//lattice[(i * M + j) / 8] = pt_index % 2;
			//setSpin(i, j, (i + j) % 2, lattice, N, M);
			//setSpin(i, j, rand_real(0, 1, &state) < 0.25f, lattice, N, M);
		}

		//barrier(CLK_GLOBAL_MEM_FENCE);
	}

	//setSpin(i, j, rand_real(0, 1, &state) < 0.5f, lattice, N, M);
	//setSpin(i, j, true, lattice, N, M);
}
)wqnifp";
	cl::Program::Sources sources;
	sources.push_back({ kernel_code.c_str(),kernel_code.length() });
	cl::Program program(context, sources);
	if (program.build({ device }) != CL_SUCCESS) {
		std::cout << " Error building: " << program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(device) << "\n";
		exit(1);
	}
	//std::cout << device.getInfo<CL_DEVICE_NAME>() << std::endl;

	cl::make_kernel<cl::Buffer, cl::Buffer, unsigned, unsigned, float, int> simple_add(cl::Kernel(program, "metro_step"));
	cl::NDRange global((ising.N() * ising.M() + 7) / 8);
	for (int i = 0; i < 10; ++i)
	{
		update_random_seeds();
		auto ee = simple_add(cl::EnqueueArgs(queue, global), gpu_lattice, rand_seeds, ising.N(), ising.M(), beta, 0);
		ee.wait();
		simple_add(cl::EnqueueArgs(queue, global), gpu_lattice, rand_seeds, ising.N(), ising.M(), beta, 1);
		ee.wait();
	}
	//std::cout << ee.getInfo<CL_EVENT_COMMAND_EXECUTION_STATUS>() << std::endl;
	//std::cout << " Error building: " << program.getBuildInfo<>(device) << "\n";
	queue.flush();

	size_t i = 0;
	size_t j = 0;
	auto placeBit = [&](bool value) {
		if (i >= ising.N())
			return;

		ising[{i, j}] = value;
		++j;
		if (j >= ising.M())
		{
			j = 0;
			++i;
		}
	};

	data.clear();
	size_t read = 0;
	size_t to_read = (ising.N() * ising.M() + 7) / 8;
	while (to_read > 0) {
		size_t readDim = std::min<size_t>(to_read, 10000);
		data.resize(readDim);
		queue.enqueueReadBuffer(gpu_lattice, CL_TRUE, read, sizeof(uint8_t) * data.size(), (void*)data.data());
		queue.flush();
		//queue.finish();

		for (const uint8_t& byte : data)
			for (int i = 0; i < 8; ++i)
				placeBit(byte & (1 << i));
		read += readDim;
		to_read -= readDim;
	}

}

double mean(const Ising2d& ising)
{
	double sum = 0;
	for (size_t i = 0; i < ising.N(); ++i)
		for (size_t j = 0; j < ising.M(); ++j)
			sum += (ising[{i, j}] ? 1.0 : -1.0);
	return sum / (ising.N() * ising.M());
}

int main(int argc, char** argv)
{
	std::cout << "Hello There!" << std::endl;

	QApplication app(argc, argv);

	auto [clctx, devices ] = init_CL_context();
	cl::Buffer A_d(*clctx, CL_MEM_READ_WRITE, sizeof(int) * 10);

	std::random_device dev;
	std::default_random_engine engine(dev());

	auto L = 1000;
	size_t N = L;
	size_t M = L;

	nm4p::Ising2d model({ N, M });
	model.randomize();

	nm4p::SimpleIsingField field;
	std::cout << "Ciao " << std::distance(field.begin(), field.end()) << std::endl;

	QImage img;

	PottsGraphicsView v; v.show();

	auto item = new Potts2dItem;

	item->showModel(model);
	std::cout << std::this_thread::get_id() << std::endl;

	std::thread t([&]() {
		std::this_thread::sleep_for(5s);
		std::cout << std::this_thread::get_id() << std::endl;
		for (double beta = 0.3; beta < 10.5; beta += 0.02)
		{
			std::cout << "beta: " << beta << std::endl;
			for (int i = 0; i < 10 || false; ++i)
			{
				//std::this_thread::sleep_for(0.01s);
				//model.randomize(engine);
				//step(model, model.N() * model.M() * 0.1, beta, engine);
				GPU_step(model, model.N() * model.M() * 0.1, beta, *clctx, devices[0], engine);
				//std::cout << "\r" << nm4p::cursor_up << reset_cursor(model) << model << " " << mean(model) << std::endl;
				//std::cout << mean(model) << std::endl;
				item->showModel(model);
				//std::cout << mean(model) << std::endl;
			}
		}
		});
	t.detach();

	QGraphicsScene scene;
	scene.setBackgroundBrush(QBrush(qRgb(30, 30, 30)));
	scene.addItem(item);

	v.setScene(&scene);


	return app.exec();


	//cl::Platform default_platform = all_platforms[0];
	//std::cout << "Using platform: " << default_platform.getInfo<CL_PLATFORM_NAME>() << "\n";

	for (auto [i, v] : field)
	{
		std::cout << i[0] << " " << i[1] << " " << v << std::endl;
	}

	constexpr auto ss = []() constexpr -> double {
		double s = 0;
		nm4p::SimpleIsingField field;
		for (auto [i, v] : field)
		{
			s += v;
		}
		return s;
	}();

	//return 0;

	

	//std::cout << model << std::endl;
	//model.randomize();
	//std::cout << "\r" << nm4p::cursor_up << reset_cursor(model) << model << std::endl;

	for (int i = 0; i < 10000; ++i)
	{
		//std::this_thread::sleep_for(0.05s);
		//model.randomize(engine);
		step(model, model.N() * model.M() * 0.5, 0.4, engine);
		//std::cout << "\r" << nm4p::cursor_up << reset_cursor(model) << model << " " << mean(model) << std::endl;
		std::cout << mean(model) << std::endl;
	}

	

	//auto n = engine();


	return 0;
}