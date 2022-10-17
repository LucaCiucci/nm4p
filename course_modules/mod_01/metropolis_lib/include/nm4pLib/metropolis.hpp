
#include <functional>
#include <random>
//#include <optional>
#include <vector>

namespace nm4pLib
{

	using std::function;
	using std::default_random_engine;

	// 1-D distribution function
	using Distrib1dFun = function<double(double)>;

	// ! this is the default random engine used by the algorithms
	// Note that this is not thread safe, but we don't care
	// to create a proper thread-dependant default engine provider for
	// the scope of the course
	extern default_random_engine default_engine;

	struct metropolis_1d_result
	{
		double acceptance = 0;
		double finalDelta = 0;
	};

	struct metropolis_1d_result2
	{
		double acceptance = 0;
		double finalDelta = 0;
		std::vector<double> xx;
	};

	/*struct metropolis_1d_options
	{
		struct AdaptiveDeltaOptions {
			bool enabled = false;
			bool local
			double targetAcceptance = 0.4;
			size_t checkEveryNSteps = 1000;
			double deltaReductionFactor = 0.9;
		};

		AdaptiveDeltaOptions adaptiveDelta;
	};*/

	/**
	 * This is a simple metropolis 1-D implementation.
	 * There are a lots of possible implementations, here we require
	 * a distribution to sample `distrib`, a start value and the max possible
	 * move length (delta) `d`.
	 * We do not return an array because this might be unnecessary, but we return
	 * the value by calling the provided `handler` that will perform arbitrary code
	 * using the provided draw.
	 *
	 * Note that a random engine can be provided, this allows to produce
	 * consistent results, particularly useful while debugging.
	 *
	 *
	 * @param distrib     the distribution we want to sample
	 * @param startValue  the initial sample value, this is not emitted
	 * @param engine      the random engine to use
	 * @param d           the width of the moving step
	 * @param nPoints     the number of draws to generate
	 * @param handler     the function that will be called every time a value is generated
	 * @param stride      iterations for each draw
	 * @param forceStep   effectively set acceptance = 1 by repeating the iteration if not accepted
	*/
	metropolis_1d_result metropolis_1d(
		Distrib1dFun distrib,
		const double startValue,
		double d,
		const size_t nPoints,
		std::function<void(double)> handler,
		const size_t stride = 1,
		bool forceStep = false,
		std::default_random_engine& engine = default_engine
		//const metropolis_1d_options& = {}
	);

	metropolis_1d_result2 metropolis_1d(
		Distrib1dFun distrib,
		const double startValue,
		double d,
		const size_t nPoints,
		std::function<double(double)> transformer,
		const size_t stride = 1,
		bool forceStep = false,
		std::default_random_engine& engine = default_engine
		//const metropolis_1d_options& = {}
	);

	metropolis_1d_result2 metropolis_1d(
		Distrib1dFun distrib,
		const double startValue,
		double d,
		const size_t nPoints,
		const size_t stride = 1,
		bool forceStep = false,
		std::default_random_engine& engine = default_engine
		//const metropolis_1d_options& = {}
	);
}