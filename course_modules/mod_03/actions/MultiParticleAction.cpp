
#include <numbers>

#include "MultiParticleAction.hpp"

// TODO move
namespace {
	//double hbar = 6.62607015E-34 / (2 * std::numbers::pi); // m^2 kg / s
	double hbar = 1;
}

namespace nm4p
{
	MultiParticleAction::MultiParticleAction(double beta, Potential potential, vector<double> messes) :
		beta(beta),
		potential(potential),
		masses(messes)
	{
	}

	double MultiParticleAction::kin(size_t i, size_t N) const
	{
		return (N) / (2 * this->beta * hbar * hbar) * this->masses[i];
	}
	
	double MultiParticleAction::veff(const span<const double>& yy) const
	{
		const auto N = yy.size();
		Eigen::VectorXd xx(N);
		for (size_t i = 0; i < N; ++i)
			xx[i] = yy[i];
		return this->potential(xx) * (this->beta / N);
	}
}