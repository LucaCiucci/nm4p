
#pragma once

#include "AbstractMultiParticleAction.hpp"

namespace nm4p
{
	struct HO_1P_Action final : AbstractMultiParticleAction
	{
		HO_1P_Action(double eta) : eta(eta) {}

		double kin(size_t i, size_t N) const override;
		double veff(const span<const double>& yy) const override;

	public:

		const double eta = 0;
	};
}