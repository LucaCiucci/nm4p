
#include <cassert>
#include <string>
#include <array>

#include "AbstractMultiParticleAction.hpp"

#include <nm4pLib/utils/math.hpp>

using lc::experimental::sqr;
using namespace std::string_literals;
using std::array;

namespace nm4p
{
	double AbstractMultiParticleAction::eval(const Trajectory& t) const
	{
		double sum_v = 0;
		const auto N = t.lenght();

		for (size_t J = 0; J < N; ++J)
		{
			// kinetic term
			for (size_t i = 0; i < t.nComponents(); ++i)
				sum_v += this->kin(i, N) * sqr(t[(J + 1) % N][i] - t[J][i]);

			// potential term
			sum_v += this->veff(t[J], N);
		}

		return sum_v;
	}

	double AbstractMultiParticleAction::evalDiff(const Trajectory& t, size_t i0, const Trajectory::Point& testPoint) const
	{
		return this->evalDiff_impl(t, i0, testPoint, false);
	}

	GuessProvider AbstractMultiParticleAction::guessProvider(double alpha, GuesserKind kind)
	{
		return [alpha, kind](Trajectory::Point& guess, const Trajectory& trajectory, const TrajectoryAction& actionFunctional, size_t i0, random_engine& engine) -> void {
			if (auto functional = dynamic_cast<const AbstractMultiParticleAction*>(&actionFunctional))
			{
				const auto N = trajectory.lenght();
				guess.resize(trajectory.nComponents());
				std::copy(trajectory[i0].begin(), trajectory[i0].end(), guess.begin());

				for (size_t i = 0; i < guess.size(); ++i)
				{
					const auto sigma = sqrt(1 / functional->kin(i, N));
					const auto delta = sigma * alpha;

					switch (kind)
					{
					case GuesserKind::Uniform:
						guess[i] += std::uniform_real_distribution<double>(-delta, delta)(engine);
						break;
					case GuesserKind::Gaussian:
						guess[i] += std::normal_distribution<double>(0, delta)(engine);
						break;
					default:
						assert(0);
					}
				}
			}
			else
			{
				throw std::runtime_error(
					"guessProvider: actionFunctional is not an AbstractMultiParticleAction instance but "s
					+ typeid(actionFunctional).name()
				);
			}
		};
	}

	double AbstractMultiParticleAction::evalDiff_impl(const Trajectory& t, size_t i0, const Trajectory::Point& testPoint, bool kineticOnly) const
	{

		// this *_impl was intendet to provide a way of computing the second derivative of the action functional
		// this was an old unnecessary idea, remove this function and place everything in `evalDiff`

		const auto N = t.lenght();
		double sum_v = 0;

		auto modifiedTrajectory = [&](size_t j) -> span<const double> { return j == i0 ? testPoint : t[j]; };
		auto originalTrajectory = [&](size_t j) -> span<const double> { return t[j]; };

		// kinetic term
		for (const auto& J : std::array{ (i0 + N - 1) % N, i0 })
			for (size_t i = 0; i < t.nComponents(); ++i)
			{
				auto ki = this->kin(i, N);
				sum_v += ki * sqr(modifiedTrajectory((J + 1) % N)[i] - modifiedTrajectory(J)[i]);
				sum_v -= ki * sqr(originalTrajectory((J + 1) % N)[i] - originalTrajectory(J)[i]);
			}

		// potential term
		if (!kineticOnly)
		{
			const auto& J = i0;
			sum_v += this->veff(testPoint, N);
			sum_v -= this->veff(t[J], N);
		}

		return sum_v;
	}
}