
#include <nm4pLib/utils/math.hpp>

#include "HO_1P_Action.hpp"

using lc::experimental::sqr;

namespace nm4p
{
	double HO_1P_Action::kin(size_t i, size_t N) const
	{
		return 1 / (2 * this->eta);
	}

	double HO_1P_Action::veff(const span<const double>& yy) const
	{
		// a quadratic potential
		double sum_v = 0;
		for (const double& y : yy)
			sum_v += sqr(y);
		return 0.5 * this->eta * sum_v;
	}
}