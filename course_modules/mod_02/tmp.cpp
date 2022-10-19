

#include <iostream>

#include <Eigen/Eigen>

int main()
{
	Eigen::Matrix2d M({
		{ 1, 2 },
		{ 3, 4 }
		});

	std::cout << M.eigenvalues() << std::endl;

	Eigen::EigenSolver<decltype(M)> solver;
	std::cout << solver.compute(M).eigenvectors() << std::endl;

	Eigen::VectorX<double> v;
	v.resize(10);
	std::cout << v << std::endl;

	return 0;
}