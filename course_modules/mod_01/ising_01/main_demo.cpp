
#include <iostream>

#include <chrono>

#include <QMainWindow>
#include <QApplication>
#include <QFile>
#include <QDirIterator>
#include <QSlider>
#include <QLabel>
#include <QLayout>
#include <QCheckBox>

#include <qgraphicsview.h>

//using namespace std;
using namespace std::chrono_literals;
using namespace std::string_literals;

#include "Potts2dItem.hpp"

//#include <gnuplotpp/gnuplotpp.hpp>

#include "PottsNd.hpp"
#include "NeighborsIterator.hpp"
#include <nm4pLib/utils/strings.hpp>

#include "opencl_utils.hpp"

#include "steppers.hpp"

#include <random>

using namespace nm4p;

#undef max
//#undef ISING_OPENCL

#ifdef ISING_OPENCL
#define IF_ISING_OPENCL(x) x
#else 
#define IF_ISING_OPENCL(x)
#endif

// "D:/LUCA/unipi/metodi_numerici/codici/nm4p/course_modules/mod_01/ising_01/a.ocl"

int main(int argc, char** argv)
{
	std::cout << "Hello There!" << std::endl;

	QApplication app(argc, argv);

#ifdef ISING_OPENCL
	auto [clctx, devices] = init_CL_context();
	cl::Buffer A_d(*clctx, CL_MEM_READ_WRITE, sizeof(int) * 10);
#endif // ISING_OPENCL

	std::random_device dev;
	std::default_random_engine engine(dev());

	auto L = 500;
	size_t N = L;
	size_t M = L;

	nm4p::Ising2d model({ N, M });
	model.randomize();

	nm4p::SimpleIsingField field;

	PottsGraphicsView v; v.show();

	auto item = new Potts2dItem;
	item->showModel(model);

	double betaaaa = 4;
	int stepPauseMs = 0;
	bool onGPU = false;

#ifdef ISING_OPENCL
	OpenCLIsingStepper GPU_stepper(model, *clctx, devices[0]);
#endif // ISING_OPENCL
	SimpleMetropolisIsingStepper stepper(model);

	std::thread t([&]() {
		std::this_thread::sleep_for(5s);
		std::cout << std::this_thread::get_id() << std::endl;
		for (double beta = 0.3; beta < 10.5+1000; beta += 0.02)
		{
			if (beta > 1.2)
			{
				beta = 0.3;
				model.randomize();
				continue;
			}
			beta = 0.45;

			std::cout << "beta: " << beta << std::endl;
			for (int i = 0; i < 10 || false; ++i)
			{
				//std::this_thread::sleep_for(0.01s);
				std::this_thread::sleep_for(1ms * stepPauseMs);
				//model.randomize(engine);
				//step(model, model.N() * model.M() * 0.1, beta, engine);
				//GPU_step(model, model.N() * model.M() * 0.1, betaaaa, *clctx, devices[0], engine);
				IF_ISING_OPENCL(GPU_stepper.repetitions = 1);
				//stepper.steps = 10;

				if (onGPU)
					IF_ISING_OPENCL(GPU_stepper.step(engine));
				else
					stepper.step(engine);

				//std::cout << "\r" << nm4p::cursor_up << reset_cursor(model) << model << " " << mean(model) << std::endl;
				//std::cout << mean(model) << std::endl;
				item->showModel(model);
				std::cout << magnetization(model) << std::endl;
			}
		}
		});
	t.detach();

	QGraphicsScene scene;
	scene.setBackgroundBrush(QBrush(qRgb(30, 30, 30)));
	scene.addItem(item);

	v.setScene(&scene);


	QVBoxLayout layout;
	QLabel label;
	label.setText("BETA");
	layout.addWidget(&label);
	QSlider slider; slider.setMaximum(1000); QObject::connect(&slider, &QSlider::valueChanged, [&]() {
		betaaaa = std::lerp(0.2, 0.8, (double)slider.value() / 1000);
		label.setText(QString::fromStdString(std::format("Beta = {:.3}", betaaaa)));
		IF_ISING_OPENCL(GPU_stepper.setBeta(betaaaa));
		stepper.setBeta(betaaaa);
		});
	slider.setOrientation(Qt::Horizontal);
	layout.addWidget(&slider);
	QSlider pauseMsSlider;
	pauseMsSlider.setMaximum(1000);
	QObject::connect(&pauseMsSlider, &QSlider::valueChanged, [&]() {
		auto s = pauseMsSlider.value();
		stepPauseMs = std::exp(std::lerp(std::log(0.01), std::log(1000), (double)s / pauseMsSlider.maximum()));
		});
	pauseMsSlider.setOrientation(Qt::Horizontal);
	layout.addWidget(&pauseMsSlider);
	QCheckBox checkbox;
	checkbox.setText("GPU");
	layout.addWidget(&checkbox);
	QObject::connect(&checkbox, &QCheckBox::stateChanged, [&]() {
		onGPU = checkbox.isChecked();
		});
	
	QWidget widget;
	widget.setLayout(&layout);
	widget.show();



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

	//auto n = engine();


	return 0;
}


typedef struct _xorshift32_state {
	unsigned a;
} xorshift32_state;

/* The state word must be initialized to non-zero */
inline constexpr unsigned xorshift32(xorshift32_state* state)
{
	/* Algorithm "xor" from p. 4 of Marsaglia, "Xorshift RNGs" */
	unsigned x = state->a;
	x ^= x << 13;
	x ^= x >> 17;
	x ^= x << 5;
	return state->a = x;
}

inline constexpr int pb(int i, int N) {
	if (i < 0)
		return (N + (i % N)) % N;

	return i % N;
}

void oifneior() {
	constexpr auto a = []() constexpr {
		return pb(-5, 4);
	}();
}