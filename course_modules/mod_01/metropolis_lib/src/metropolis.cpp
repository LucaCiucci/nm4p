
#include <cassert>

#include <nm4pLib/metropolis.hpp>

using std::uniform_real_distribution;

namespace nm4pLib
{
	////////////////////////////////////////////////////////////////
	default_random_engine default_engine;

	////////////////////////////////////////////////////////////////
	metropolis_1d_result metropolis_1d(
		Distrib1dFun distrib,
		const double startValue,
		double d,
		const size_t nPoints,
		std::function<void(double)> handler,
		const size_t stride,
		bool forceStep,
		std::default_random_engine& engine
	)
	{
		assert(distrib);
		assert(handler);

		// `d` must be finite, we perform some runtime checks
		if (d <= 0) throw std::invalid_argument("metropolis_1d requires d > 0");
		if (!std::isfinite(d)) throw std::invalid_argument("metropolis_1d requires d to be finite");

		// ensures p >= 0
		// we create a "healed" distribution so that negative or
		// or non-finite results are never returned, instead, 0 is returned
		// in theese bad cases so that non-* points are never sampled
		auto healed_distrib = [&distrib](double x) {
			auto p = distrib(x);
			auto ok = p >= 0 && std::isfinite(p);
			assert(ok);
			return ok ? p : 0;
		};

		// a uniform distribution ranging (-delta, delta)
		// used to determine the next position
		uniform_real_distribution<double> dd(-d, d);

		// see `true_with_probability`
		uniform_real_distribution<double> _xx(0, 1);

		// returns true with the specified probability
		auto true_with_probability = [&_xx, &engine](double p) {
			if (!isfinite(p)) [[unlikely]]
				return false;
			if (p < 0)
				return false;
			if (p >= 1)
				return true;
			return _xx(engine) < p;
		};

		// returns the ration `num/den`, but some non-well-defined cases are threated
		// separately: in particular, we don't want to sample points where
		// the ratio is not a probability, in those cases, we return 0
		auto probability_ratio = [](double num, double den) -> double {

			// we do not want to end up in a place where the distribution
			// is not fitite, so we set num = 0 so that, if the den is valid,
			// we never and up in this point
			if (!isfinite(num)) [[unlikely]]
				num = 0;

			// if the current probability is 0, we want to move away,
			// see cases below
			if (!isfinite(den)) [[unlikely]]
				den = 0;

			if (num < 0) [[unlikely]] num = 0;
			if (den < 0) [[unlikely]] den = 0;

			// this condition should never verify in the metropolis algorithm
			// since current.p should never be 0 aside (possibly) from the first steps
			// we want to return 1 when the ratio is 0/0 or #/0 so that, in those cases,
			// wa always step
			if (den == 0) [[unlikely]] return 1;

			return num / den;
		};

		struct Point
		{
			double value = 0;
			double p = 0;
		};

		// the current point
		// on every metropolis step, we will update this point
		Point current = {
			.value = startValue,
			.p = healed_distrib(startValue)
		};

		size_t accepted_count = 0;
		size_t total_count = 0;

		// ================================
		// The actual algorithm starts here

		// we want to generate nPoints...
		for (size_t i = 0; i < nPoints; ++i)
		{
			// ... performing `stride` iterations of the procedure for each one
			for (int i = 0; i < stride; ++i)
				while (true)
				{
					// pick the next point "a", (the process is "b -> a")
					Point next;
					next.value = current.value + dd(engine);
					next.p = healed_distrib(next.value);
					++total_count;

					const bool accepted = true_with_probability(probability_ratio(next.p, current.p));

					if (accepted)
						(current = next), (++accepted_count);

					// we have finished, buf if forceStep is set and we have not moved, repeat
					if (!forceStep || accepted)
						break;
				}

			// emit the value
			handler(current.value);
		}

		return metropolis_1d_result {
			.acceptance = total_count == 0 ? 0 : double(accepted_count) / total_count
		};
	}

	////////////////////////////////////////////////////////////////
	metropolis_1d_result2 metropolis_1d(
		Distrib1dFun distrib,
		const double startValue,
		double d,
		const size_t nPoints,
		std::function<double(double)> transformer,
		const size_t stride,
		bool forceStep,
		std::default_random_engine& engine
		//const metropolis_1d_options& = {}
	)
	{
		std::vector<double> data;
		auto handler = [&data](double value) {
			data.push_back(value);
		};

		metropolis_1d_result partialResult = metropolis_1d(distrib, startValue, d, nPoints, handler, stride, true, engine);

		metropolis_1d_result2 result;
		result.acceptance = partialResult.acceptance;
		result.finalDelta = partialResult.finalDelta;
		result.xx = std::move(data);

		return result;
	}

	////////////////////////////////////////////////////////////////
	metropolis_1d_result2 metropolis_1d(
		Distrib1dFun distrib,
		const double startValue,
		double d,
		const size_t nPoints,
		const size_t stride,
		bool forceStep,
		std::default_random_engine& engine
		//const metropolis_1d_options& = {}
	)
	{

		return metropolis_1d(distrib, startValue, d, nPoints, (std::function<double(double)>)[](double x) { return x; }, stride, true, engine);
	}
}