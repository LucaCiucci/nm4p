
#include "metropolis.hpp"


namespace nm4p
{
	void metropolis(
		Trajectory& trajectory,
		const TrajectoryAction& actionFunctional,
		IndexRunner indexRunner,
		GuessProvider guessProvider,
		size_t repetitions,
		MetroCallback callback,
		random_engine& engine
	)
	{
		// this is the guess generated by the guess provider
		// it is placed outside the loop to avoid reallocation
		Trajectory::Point guess;

		std::uniform_real_distribution<double> xDist(0, 1);
		auto trueWithProbability = [&](double p) { return xDist(engine) < p; };

		for (size_t iteration = 0; iteration < repetitions; ++iteration)
		{
			bool ok = true;
			size_t indexIteration = 0;

			// run through the indexes
			indexRunner(
				(IndexConsumer)[&](size_t i0) {
					if (!ok)
						// a previous iteration has already told to stop
						return;

					// should not be necessary, but just in case (clear will not deallocate memory but will set the size to 0)
					guess.clear();

					// generate a guess
					guessProvider(guess, trajectory, actionFunctional, i0, engine);

					// evaluate the action difference
					const double deltaS = actionFunctional.evalDiff(trajectory, i0, guess);

					// TODO vedi modulo 1 per tutte le accortezze del caso

					const double r = std::exp(-deltaS);
					const bool accept = trueWithProbability(r);

					if (accept)
						// copy the guess into the trajectory
						std::copy(guess.begin(), guess.end(), trajectory[i0].begin());

					// call the callback
					const bool cbok = callback(trajectory, iteration, indexIteration++, accept);
					ok = ok && cbok;
				},
				trajectory,
				actionFunctional
			);

			if (!ok)
				// the callback returned false, so we should stop
				break;
		}
	}
}
