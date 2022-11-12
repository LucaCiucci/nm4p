
#pragma once

#include <functional>
#include <random>

#include "Trajectory.hpp"

namespace nm4p
{
	using std::function;
	using random_engine = std::mt19937; // std::default_random_engine

	using IndexConsumer = function<void(size_t i0)>;
	using IndexRunner = function<void(IndexConsumer, const Trajectory& trajectory, const TrajectoryAction& actionFunctional)>;
	using MetroCallback = function<bool(const Trajectory&, size_t iteration, size_t indexIteration, bool accepted)>; // Note: return false to break
	using GuessProvider = function<void(Trajectory::Point& guess, const Trajectory& trajectory, const TrajectoryAction& actionFunctional, size_t i0, random_engine& engine)>;

	inline IndexRunner default_index_runner = [](IndexConsumer consumer, const Trajectory& trajectory, const TrajectoryAction& actionFunctional) {
		for (size_t i = 0; i < trajectory.lenght(); ++i)
			consumer(i);
	};

	void metropolis(
		Trajectory& trajectory,
		const TrajectoryAction& actionFunctional,
		IndexRunner indexRunner,
		GuessProvider guessProvider,
		size_t repetitions,
		MetroCallback callback,
		random_engine& engine
	);
}