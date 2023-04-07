
#pragma once

#include "AbstractMultiParticleAction.hpp"

#include <Eigen/Core>

namespace nm4p
{
	class MultiParticleAction : public AbstractMultiParticleAction
	{
	public:

		using Potential = function<double(const Eigen::VectorXd&)>;

		MultiParticleAction(double beta, Potential potential, vector<double> messes);

		double beta;
		Potential potential;
		vector<double> masses;

		double kin(size_t i, size_t N) const override;
		double veff(const span<const double>& yy, size_t N) const override;
		
	private:
		
	};
}