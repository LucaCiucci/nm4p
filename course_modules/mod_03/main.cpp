
#include <iostream>


#include <format>
#include <string>
#include <random>
#include <array>
#include <cassert>

//#include <Eigen/Core>

#include <nm4pLib/utils/math.hpp>

#include "Trajectory.hpp"
#include "metropolis.hpp"
#include "actions/HO_1P_Action.hpp"
#include "actions/MultiParticleAction.hpp"

#include <QImage>

namespace nm4p
{
	using std::array;
	using namespace std::string_literals;

	
}

std::ostream& operator<<(std::ostream& os, const nm4p::Trajectory& trajectory)
{
	for (size_t i = 0; i < trajectory.lenght(); ++i)
	{
		for (const auto& v : trajectory[i])
			os << v << " ";
		os << std::endl;
	}

	return os;
}

int main(int argc, char** argv)
{
	std::cout << "Hello There!" << std::endl;

	using namespace nm4p;

	Trajectory t(2, 10000);
	t[0][0] = -1;
	std::cout << "trajectory" << std::endl;
	std::cout << t << std::endl;

	random_engine engine;

	
	const auto guessProvider = AbstractMultiParticleAction::guessProvider(1, AbstractMultiParticleAction::GuesserKind::Gaussian);

	const auto actionFunctional = HO_1P_Action(0.1);
	const auto af2 = MultiParticleAction(1.1, [](const Eigen::VectorXd& p) -> double {
		auto r2 = p.norm() * p.norm();
		return r2;
		return -1 / (p.norm() + 0.01*0);
		}, {1, 1, 1, 1, 1, 1});
	
	AverageAccumulator x_2_avg;

	QImage img(1000, 1000, QImage::Format_RGB32);

	const MetroCallback callback = [&](const Trajectory& trajectory, size_t iteration, size_t indexIteration, bool accepted) {
		if (indexIteration == 0) x_2_avg << trajectory[0][0] * trajectory[0][0];
		if (iteration % 1000 == 0 && indexIteration == 0) std::cout << trajectory[0][0] * trajectory[0][0] + trajectory[1][0] * trajectory[1][0] << "\r";
		//if (iteration % 10000 == 0 && indexIteration == 0) std::cout << "\n";
		//if (iteration % 1000 == 0 && indexIteration == 0) std::cout << "x_2_avg = " << x_2_avg() << "\r";
		
		if (iteration == 999 && indexIteration == 0) {
			for (size_t i = 0; i < trajectory.lenght(); ++i) {
				// draw a pixel on the image
				auto x = trajectory[i][0];
				auto y = trajectory[i][1];

				const double L = 0.25;
				const double minXView = -L;
				const double maxXView = L;
				const double minYView = -L;
				const double maxYView = L;

				const double xView = (x - minXView) / (maxXView - minXView);
				const double yView = (y - minYView) / (maxYView - minYView);

				const int xImg = xView * img.width();
				const int yImg = yView * img.height();

				if (xImg >= 0 && xImg < img.width() && yImg >= 0 && yImg < img.height())
				{
					img.setPixel(xImg, yImg, 0x00ff00);
					//auto color = img.pixelColor(xImg, yImg);
					//color.setRgb(color.red() + 1, color.green() + 1, color.blue() + 1);
					//img.setPixelColor(xImg, yImg, color);
				}
				//img.setPixel(xImg, yImg, 0x00ff00);	
			}
		}

		return true;
		
		if (indexIteration != 0)
			return true;

		std::cout << "iteration " << iteration << ", index iteration " << indexIteration << ", accepted " << accepted << std::endl;
		std::cout << trajectory << std::endl;
		std::cout << actionFunctional.eval(trajectory) << std::endl;

		return true;
	};

	metropolis(t, af2, default_index_runner, guessProvider, 1000, callback, engine);

	img.save("ciao.png");

	std::cout << "x_2_avg = " << x_2_avg() << std::endl;

	std::cout << "trajectory" << std::endl;
	std::cout << "---" << std::endl << t << "---" << std::endl;

	return 0;
}