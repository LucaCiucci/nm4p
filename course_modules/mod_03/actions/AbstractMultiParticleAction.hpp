
#pragma once

#include "../Trajectory.hpp"
#include "../metropolis.hpp"

namespace nm4p
{
	struct AbstractMultiParticleAction : TrajectoryAction
	{
	public:

		double eval(const Trajectory& t) const override final;

		double evalDiff(const Trajectory& t, size_t i0, const Trajectory::Point& testPoint) const override;

		virtual double kin(size_t i, size_t N) const = 0;
		virtual double veff(const span<const double>& xx) const = 0;

		enum class GuesserKind {
			Uniform,
			Gaussian,
		};

		static GuessProvider guessProvider(double alpha, GuesserKind kind);

	private:
		double evalDiff_impl(const Trajectory& t, size_t i0, const Trajectory::Point& testPoint, bool kineticOnly) const;
	};
}